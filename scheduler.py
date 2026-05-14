import os
import logging
import json
from typing import List, Dict
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
from supabase import create_client, Client
from groq import Groq

# --- Config & Logging ---
load_dotenv()
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Initialization ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
# Use Service Role Key for background tasks to bypass RLS
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

if not all([SUPABASE_URL, SUPABASE_KEY, GROQ_API_KEY]):
    logger.error("Missing environment variables! Check your .env or GitHub Secrets.")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
groq_client = Groq(api_key=GROQ_API_KEY)

class PerformanceTracker:
    def __init__(self):
        self.history_table = "user_performance_history"
        self.model_name = "llama-3.1-8b-instant"

    def fetch_all_users(self) -> List[str]:
        """Discovers unique users who have any activity."""
        try:
            # We look at the history table to see existing users
            response = supabase.table(self.history_table).select("user_id").execute()
            return list(set([r['user_id'] for r in response.data if r.get('user_id')]))
        except Exception as e:
            logger.error(f"Error fetching users: {e}")
            return []

    def is_due_for_refresh(self, user_id: str) -> bool:
        """Checks if 3 days have passed since the last update for this user."""
        try:
            response = supabase.table(self.history_table)\
                .select("created_at")\
                .eq("user_id", user_id)\
                .order("created_at", desc=True)\
                .limit(1).execute()
            
            if not response.data:
                return True # No history? Process them now.
            
            last_update_str = response.data[0]['created_at']
            last_update = datetime.fromisoformat(last_update_str.replace('Z', '+00:00'))
            
            time_diff = datetime.now(timezone.utc) - last_update
            # We use max(0, seconds) to handle cases where clock drift makes the diff negative
            return time_diff.total_seconds() >= timedelta(days=1).total_seconds()
        except Exception as e:
            logger.error(f"Error checking due date for {user_id}: {e}")
            return True

    def fetch_module_data(self, user_id: str, table_name: str) -> str:
        """Fetches the last 10 interactions from a specific module table."""
        try:
            user_col = "user_input" if "image" in table_name else "user_message"
            ai_col = "ai_output" if "image" in table_name else "ai_message"
            date_col = "created_at"
            
            response = supabase.table(table_name)\
                .select(f"{user_col}, {ai_col}")\
                .eq("user_id", user_id)\
                .order(date_col, desc=True)\
                .limit(10).execute()
            
            if not response.data:
                return ""
            
            return "\n".join([f"User: {r[user_col]}\nAI: {r[ai_col]}" for r in response.data])
        except Exception as e:
            logger.warning(f"Could not fetch from {table_name}: {e}")
            return ""

    def get_analysis_scores(self, transcript: str, module_type: str) -> Dict:
        """Sends transcript to Groq for linguistic scoring."""
        if not transcript:
            return {}

        prompt = f"""
        Analyze this {module_type} transcript for a student aged 10-16. 
        Evaluate: Grammar, Vocabulary, and Clarity.
        Return ONLY a JSON with scores 1.0 to 10.0.
        
        CRITICAL: 
        - Use ONLY numbers (floats). 
        - NEVER use 'N/A', 'null', or strings. 
        - If data is missing or empty, return 0.0 for that score.
        
        Keys:
        - For 'vocabulary': {{"vocabulary_score": X.X, "sentence_formation_score": X.X}}
        - For 'interaction': {{"ai_interaction_score": X.X}}
        - For 'narration': {{"image_narration_score": X.X}}

        Transcript:
        {transcript}
        """

        import time
        time.sleep(2) # Avoid 429 Rate Limits
        try:
            response = groq_client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {"role": "system", "content": "You are a helpful linguistic coach. Respond in JSON only."},
                    {"role": "user", "content": prompt}
                ],
                response_format={"type": "json_object"}
            )
            return json.loads(response.choices[0].message.content)
        except Exception as e:
            logger.error(f"Groq API Error: {e}")
            return {}

    def run_pipeline(self):
        logger.info(f"🚀 Starting AI Performance Analysis Engine")
        user_ids = self.fetch_all_users()
        
        for uid in user_ids:
            if not self.is_due_for_refresh(uid):
                logger.info(f"⏳ User {uid} updated recently. Skipping.")
                continue

            logger.info(f"🔍 Analyzing User: {uid}")
            user_scores = {}

            # 1. Vocabulary & Sentence Formation (from sentence_logs)
            user_scores.update(self.get_analysis_scores(self.fetch_module_data(uid, "sentence_logs"), "vocabulary"))
            
            # 2. AI Interaction (Combined from conversation_logs and role_play_logs)
            conv_data = self.fetch_module_data(uid, "conversation_logs")
            role_data = self.fetch_module_data(uid, "role_play_logs")
            combined_interaction = f"Conversation:\n{conv_data}\n\nRole Play:\n{role_data}"
            user_scores.update(self.get_analysis_scores(combined_interaction, "interaction"))
            
            # 3. Image Narration (from image_narration_logs)
            user_scores.update(self.get_analysis_scores(self.fetch_module_data(uid, "image_narration_logs"), "narration"))

            # Whitelist of valid columns in user_performance_history
            valid_columns = {
                "vocabulary_score", 
                "sentence_formation_score", 
                "image_narration_score", 
                "ai_interaction_score"
            }

            if user_scores:
                cleaned = {}
                for k, v in user_scores.items():
                    if k not in valid_columns: continue
                    if v is None: continue
                    try:
                        # Extract score if AI returned a nested object like {"score": 8.5}
                        if isinstance(v, dict):
                            val = v.get('score') or list(v.values())[0]
                            cleaned[k] = round(float(val), 1)
                        else:
                            cleaned[k] = round(float(v), 1)
                    except (ValueError, TypeError, IndexError):
                        logger.warning(f"Skipping invalid score for {k}: {v}")
                
                if cleaned:
                    try:
                        cleaned["user_id"] = uid
                        cleaned["created_at"] = datetime.now(timezone.utc).isoformat()
                        
                        supabase.table(self.history_table).insert(cleaned).execute()
                        logger.info(f"✅ Success: Dashboard updated for {uid}")
                    except Exception as e:
                        logger.error(f"❌ DB Error for {uid}: {e}")
                else:
                    logger.warning(f"⚠️ No valid scores to save for {uid}")

        logger.info("🏁 Pipeline Execution Completed.")

if __name__ == "__main__":
    tracker = PerformanceTracker()
    tracker.run_pipeline()
