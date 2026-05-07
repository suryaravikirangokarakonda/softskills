import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/navbar.dart';
import '../widgets/voice_interaction_widget.dart';

// Full vocabulary list
const List<String> _vocabularyWords = [
  'active', 'ankle', 'anyway', 'argue', 'article', 'author', 'avoid',
  'believe', 'blank', 'blow', 'castle', 'cause', 'cent', 'celebrity',
  'check', 'clearly', 'clever', 'cloud', 'coach', 'coast', 'collect',
  'college', 'corner', 'cover', 'crazy', 'crime', 'crowd', 'deal',
  'dentist', 'destroy', 'device', 'diary', 'disagree', 'disease', 'desert',
  'design', 'discuss', 'distance', 'divorced', 'drop', 'dry', 'early',
  'earn', 'effect', 'energy', 'error', 'event', 'everyday', 'everywhere',
  'exact', 'exactly', 'exercise', 'expert', 'fact', 'factor', 'farm',
  'farming', 'fear', 'feed', 'field', 'illness', 'imagine', 'injury',
  'insect', 'introduce', 'invitation', 'invite', 'item', 'jewellery',
  'joke', 'journalist', 'journey', 'knowledge', 'lazy', 'lead', 'leave',
  'lifestyle', 'loud', 'mail', 'material', 'meaning', 'medical', 'narrow',
  'natural', 'nature', 'pair', 'period', 'population', 'position', 'prison',
  'prize', 'professor', 'protect', 'pull', 'raise', 'receive', 'recent',
  'recently', 'react', 'reduce', 'request', 'respond', 'replace', 'scary',
  'skin', 'spell', 'stair', 'store', 'stupid', 'succeed', 'system', 'task',
  'team', 'telephone', 'television', 'thick', 'thief', 'thin', 'tip',
  'abroad', 'accept', 'accident', 'actually', 'advantage', 'adventure',
  'advertise', 'advertisement', 'advertising', 'advice', 'affect', 'afraid',
  'afternoon', 'airline', 'almost', 'alternative', 'amazing', 'ancient',
  'appearance', 'arrangement', 'asleep', 'assistant', 'athlete', 'attack',
  'attend', 'attractive', 'audience', 'average', 'beautiful', 'become',
  'begin', 'beginning', 'behave', 'behaviour', 'belong', 'benefit',
  'better', 'between', 'blonde', 'boot', 'bored', 'boring', 'borrow',
  'bread', 'bright', 'brilliant', 'busy', 'butter', 'button', 'camp',
  'camping', 'capital', 'career', 'careful', 'carefully', 'carpet',
  'certain', 'certainly', 'charity', 'classical', 'competition', 'complain',
  'complete', 'completely', 'computer', 'concert', 'condition', 'conference',
  'connect', 'connected', 'consider', 'contain', 'context', 'continent',
  'continue', 'control', 'conversation', 'creative', 'criminal', 'crowded',
  'culture', 'dancing', 'dangerous', 'decide', 'decision', 'deep',
  'definitely', 'degree', 'delicious', 'department', 'depend', 'describe',
  'description', 'designer', 'detective', 'develop', 'difference', 'different',
  'differently', 'digital', 'direct', 'direction', 'director', 'disappear',
  'disaster', 'discover', 'discovery', 'drug', 'electric', 'electrical',
  'electronic', 'email', 'employ', 'employee', 'employer', 'ending',
  'enormous', 'environment', 'equipment', 'especially', 'tool', 'figure',
  'flu', 'form', 'foreign', 'government', 'guess', 'guest', 'hide', 'hold',
  'hour', 'explain', 'explanation', 'express', 'expression', 'extreme',
  'extremely', 'feeling', 'fiction', 'focus', 'follow', 'following',
  'fork', 'fortunately', 'forward', 'friendly', 'funny', 'furniture',
  'further', 'future', 'gallery', 'general', 'greet', 'guide', 'however',
  'identify', 'immediately', 'important', 'impossible', 'include', 'included',
  'increase', 'incredible', 'independent', 'individual', 'industry',
  'informal', 'information', 'instead', 'instruction', 'instructor',
  'instrument', 'interest', 'interested', 'interesting', 'international',
  'invent', 'invention', 'tourism', 'traveller', 'upstairs', 'vacation',
  'visitor', 'waiter', 'worst', 'act', 'ability', 'manager', 'manner',
  'match', 'matter', 'mean', 'meet', 'meeting', 'member', 'memory',
  'mention', 'mile', 'million', 'modern', 'moment', 'mostly', 'movement',
  'musician', 'nearly', 'necessary', 'nervous', 'noisy', 'notice',
  'nowhere', 'opinion', 'opportunity', 'ordinary', 'organization', 'organize',
  'oven', 'owner', 'pack', 'paragraph', 'particular', 'passenger', 'passport',
  'past', 'patient', 'pattern', 'peace', 'penny', 'pepper', 'perform',
  'permission', 'personality', 'phrase', 'piano', 'picture', 'piece',
  'colleague', 'comfortable', 'comment', 'common', 'communicate', 'community',
  'compete', 'professional', 'program', 'programme', 'progress', 'project',
  'pronounce', 'provide', 'publish', 'purpose', 'quantity', 'reach',
  'realize', 'reception', 'recipe', 'recognize', 'recommend', 'recycle',
  'refer', 'refuse', 'region', 'regular', 'remember', 'report', 'research',
  'researcher', 'response', 'review', 'sail', 'sailing', 'salad', 'scared',
  'schedule', 'season', 'secondly', 'secretary', 'section', 'sense',
  'separate', 'series', 'serious', 'serve', 'service', 'shall', 'sheet',
  'should', 'shut', 'sick', 'similar', 'simple', 'essay', 'euro', 'evening',
  'evidence', 'excited', 'exciting', 'expect', 'expensive', 'experience',
  'experiment', 'storm', 'straight', 'strange', 'strategy', 'structure',
  'successful', 'suddenly', 'suggest', 'suit', 'suppose', 'surprised',
  'surprising', 'survey', 'sweater', 'symbol', 'technology', 'term',
  'terrible', 'thinking', 'thirsty', 'thought', 'tidy', 'tired', 'together',
  'tooth', 'topic', 'track', 'trainer', 'training', 'trouble', 'trousers',
  'typical', 'understand', 'understanding', 'unfortunately', 'university',
  'unusual', 'useful', 'usual', 'usually', 'valley', 'variety', 'way',
  'weak', 'wedding', 'wet', 'worried', 'worry', 'worse', 'abandon', 'pilot',
  'singing', 'involve', 'jam', 'jazz', 'knock', 'know', 'laugh', 'laughter',
  'law', 'learn', 'learning', 'lecture', 'lend', 'likely', 'line', 'link',
  'listener', 'machine', 'magazine', 'major', 'manage', 'ambition', 'anger',
  'anniversary', 'anxious', 'apparent', 'apparently', 'application',
  'appreciate', 'appropriate', 'amount', 'annoyed', 'annoying', 'artificial',
  'artistic', 'ashamed', 'associate', 'association', 'arrival', 'attempt',
  'authority', 'backwards', 'barrier', 'broadcast', 'campaign', 'candidate',
  'capable', 'category', 'ceremony', 'celebration', 'characteristic',
  'cheerful', 'circumstance', 'citizen', 'classic', 'clause', 'collapse',
  'collection', 'combination', 'platform', 'please', 'pleased', 'point',
  'polite', 'possession', 'possibility', 'possible', 'pound', 'predict',
  'prefer', 'prepare', 'present', 'pretty', 'prevent', 'probably', 'process',
  'produce', 'consumer', 'contemporary', 'continuous', 'contract', 'contrast',
  'confident', 'confirm', 'confuse', 'consume', 'contact', 'content',
  'contribute', 'convenient', 'convince', 'core', 'cottage', 'council',
  'constant', 'construct', 'convert', 'contest', 'corporate', 'countryside',
  'creation', 'creature', 'crisis', 'criterion', 'critic', 'criticism',
  'criticize', 'crucial', 'currency', 'county', 'critical', 'curved',
  'debate', 'decoration', 'deeply', 'defeat', 'single', 'situation', 'ski',
  'skiing', 'skirt', 'social', 'society', 'sock', 'solution', 'sometimes',
  'soon', 'sort', 'soup', 'speaker', 'specific', 'spelling', 'statement',
  'station', 'steal', 'detect', 'determined', 'development', 'discipline',
  'dishonest', 'dismiss', 'distribute', 'distribution', 'district',
  'division', 'documentary', 'domestic', 'dominate', 'downwards', 'draft',
  'define', 'determine', 'directly', 'disappointed', 'disappointing',
  'dislike', 'display', 'divide', 'double', 'dramatic', 'delivery', 'depth',
  'detail', 'disadvantage', 'discount', 'document', 'drag', 'dressed',
  'dust', 'eastern', 'economic', 'economy', 'edge', 'edition', 'effective',
  'accommodation', 'accompany', 'accurate', 'accuse', 'acquire', 'adapt',
  'admire', 'adopt', 'acknowledge', 'afford', 'afterwards', 'agenda',
  'aggressive', 'aircraft', 'alter', 'ambitious', 'analyse', 'analysis',
  'amazed', 'exhibition', 'existence', 'expectation', 'expense', 'exploration',
  'expose', 'episode', 'equal', 'establish', 'evaluate', 'examination',
  'expected', 'expedition', 'explosion', 'extend', 'extent', 'extraordinary',
  'facility', 'fairly', 'familiar', 'fascinating', 'fashionable', 'fasten',
  'fault', 'estate', 'examine', 'exchange', 'excuse', 'explore', 'fancy',
  'favour', 'feather', 'fee', 'fence', 'finance', 'financial', 'firm',
  'defend', 'flame', 'comfort', 'command', 'commercial', 'commission',
  'commitment', 'committee', 'commonly', 'competitor', 'complex',
  'complicated', 'component', 'concentrate', 'concept', 'concerned',
  'conclude', 'conclusion', 'confidence', 'conflict', 'confusing',
  'conscious', 'consequence', 'concentration', 'concern', 'conduct',
  'conservative', 'consideration', 'consistent', 'constantly', 'construction',
  'holy', 'honour', 'host', 'household', 'housing', 'humorous', 'humour',
  'hunting', 'hurricane', 'hunt', 'hurry', 'ideal', 'illegal', 'illustrate',
  'illustration', 'imaginary', 'imagination', 'immigrant', 'impatient',
  'imply', 'importance', 'impose', 'impressed', 'impression', 'identity',
  'ignore', 'immediate', 'impress', 'deliberate', 'deliberately',
  'demonstrate', 'debt', 'decade', 'decent', 'defence', 'definition',
  'delight', 'delighted', 'departure', 'depressed', 'depressing', 'deserve',
  'desire', 'desperate', 'dig', 'disc', 'declare', 'decline', 'decorate',
  'definite', 'delay', 'deliver', 'demand', 'deny', 'destination', 'detailed',
  'interpret', 'interrupt', 'investigation', 'investment', 'issue', 'joy',
  'judgement', 'junior', 'justice', 'justify', 'labour', 'largely', 'latest',
  'leadership', 'league', 'level', 'licence', 'limited', 'lively', 'load',
  'loan', 'landscape', 'launch', 'layer', 'leading', 'lean', 'leather',
  'legal', 'leisure', 'effectively', 'efficient', 'elderly', 'elect',
  'elsewhere', 'emerge', 'emphasis', 'emphasize', 'enable', 'encounter',
  'engage', 'engaged', 'engineering', 'enhance', 'enquiry', 'ensure',
  'educational', 'embarrassed', 'embarrassing', 'enthusiasm', 'enthusiastic',
  'entirely', 'entrance', 'essential', 'estimate', 'ethical', 'eventually',
  'evil', 'excitement', 'executive', 'musical', 'moral', 'mysterious',
  'mystery', 'narrative', 'national', 'naturally', 'neat', 'necessarily',
  'neither', 'nerve', 'nevertheless', 'nightmare', 'notion', 'numerous',
  'objective', 'obligation', 'observation', 'observe', 'obviously',
  'occasion', 'occasionally', 'offence', 'offensive', 'official', 'opening',
  'operate', 'operation', 'flash', 'flexible', 'fold', 'folding', 'folk',
  'force', 'forgive', 'fortune', 'frozen', 'furthermore', 'garage',
  'generate', 'genre', 'govern', 'grab', 'grade', 'gradually', 'grant',
  'guilty', 'handle', 'hardly', 'harmful', 'hearing', 'heel', 'hesitate',
  'highly', 'historic', 'hollow', 'phase', 'package', 'passion', 'peaceful',
  'performance', 'persuade', 'phenomenon', 'philosophy', 'pitch', 'plain',
  'planning', 'pleasant', 'pleasure', 'pile', 'plot', 'poetry', 'pointed',
  'poisonous', 'popularity', 'portrait', 'possess', 'possibly', 'potential',
  'poverty', 'powerful', 'practical', 'impressive', 'improvement', 'inch',
  'incident', 'income', 'increasingly', 'incredibly', 'indeed', 'indicate',
  'indirect', 'indoor', 'indoors', 'industrial', 'infection', 'influence',
  'hurt', 'import', 'inform', 'ingredient', 'initiative', 'injure',
  'injured', 'inner', 'innocent', 'insight', 'insist', 'inspire', 'install',
  'instance', 'institute', 'institution', 'insurance', 'intelligence',
  'intend', 'intended', 'impact', 'initial', 'initially', 'intense',
  'internal', 'publication', 'pupil', 'purchase', 'pure', 'pursue',
  'qualification', 'print', 'production', 'profession', 'proper', 'properly',
  'proposal', 'propose', 'prospect', 'protection', 'protest', 'psychologist',
  'psychology', 'literature', 'lung', 'lord', 'lower', 'maintain',
  'majority', 'massive', 'matching', 'maximum', 'means', 'meanwhile',
  'measurement', 'medium', 'melt', 'mineral', 'minimum', 'minor',
  'minority', 'mission', 'mistake', 'measure', 'mental', 'mess', 'mild',
  'mix', 'mixed', 'mixture', 'model', 'modify', 'monitor', 'motor', 'move',
  'mud', 'multiple', 'multiply', 'muscle', 'reward', 'rhythm', 'rid',
  'root', 'round', 'routine', 'relevant', 'relief', 'resolve', 'resort',
  'responsibility', 'responsible', 'retain', 'reveal', 'revolution',
  'scream', 'screen', 'seed', 'sense', 'sensitive', 'opponent', 'oppose',
  'opposed', 'nation', 'native', 'needle', 'neighbourhood', 'nuclear',
  'obey', 'object', 'obtain', 'obvious', 'occur', 'offend', 'opposition',
  'organ', 'organized', 'organizer', 'origin', 'originally', 'otherwise',
  'outer', 'outline', 'overall', 'owe', 'pace', 'pale', 'panel',
  'parliament', 'participant', 'participate', 'particularly', 'partly',
  'passage', 'pension', 'permanent', 'permit', 'perspective', 'suspect',
  'swear', 'sweep', 'switch', 'sympathy', 'symptom', 'tale', 'talented',
  'tank', 'silence', 'sincere', 'slide', 'slightly', 'software', 'somewhat',
  'specifically', 'spoken', 'sponsor', 'spot', 'spread', 'praise',
  'prediction', 'preparation', 'presence', 'preserve', 'pressure',
  'previous', 'previously', 'priest', 'prime', 'printing', 'priority',
  'prisoner', 'privacy', 'procedure', 'perfectly', 'policy', 'politician',
  'prepared', 'presentation', 'pretend', 'private', 'principle',
  'thus', 'tough', 'trade', 'translate', 'translation', 'treat', 'treatment',
  'uncomfortable', 'unconscious', 'unemployed', 'unemployment', 'unexpected',
  'unfair', 'union', 'unique', 'universe', 'unnecessary', 'unpleasant',
  'upset', 'upwards', 'qualified', 'queue', 'range', 'rapid', 'rapidly',
  'rarely', 'raw', 'realistic', 'reasonable', 'recall', 'recover',
  'reduction', 'reference', 'regard', 'regional', 'register', 'regret',
  'regulation', 'rate', 'receipt', 'recommendation', 'reflect', 'regularly',
  'relative', 'relatively', 'relaxing', 'release', 'reliable', 'religion',
  'religious', 'rely', 'remark', 'repeated', 'represent', 'representative',
  'reputation', 'require', 'requirement', 'rescue', 'reserve', 'resident',
  'resist', 'respect', 'retired', 'revise', 'sentence', 'sequence',
  'session', 'settle', 'severe', 'shade', 'shadow', 'shallow', 'shame',
  'shape', 'shell', 'shift', 'shocked', 'sight', 'significant', 'significantly',
  'similarity', 'slave', 'slight', 'slip', 'slope', 'solar', 'specialist',
  'species', 'spending', 'spirit', 'spiritual', 'split', 'spring', 'stare',
  'statistic', 'steady', 'steep', 'sticky', 'stiff', 'stock', 'stream',
  'strict', 'strike', 'struggle', 'subject', 'substance', 'successfully',
  'sum', 'surgery', 'surround', 'surrounding', 'stable', 'stage', 'stand',
  'status', 'steel', 'step', 'violence', 'tax', 'tear', 'technical',
  'technique', 'temporary', 'theme', 'theory', 'therapy', 'threat',
  'threaten', 'throat', 'tiny', 'tone', 'transfer', 'transform',
  'transition', 'trial', 'trip', 'tropical', 'truly', 'tune', 'tunnel',
  'ultimately', 'self', 'shelter', 'soul', 'southern', 'standard', 'stretch',
  'stuff', 'submit', 'suffer', 'summarize', 'summary', 'surely', 'tail',
  'target', 'urban', 'urge', 'value', 'vary', 'vast', 'venue', 'version',
  'victim', 'victory', 'viewer', 'violent', 'virtual', 'vision', 'visual',
  'vital', 'volume', 'wage', 'wealth', 'wealthy', 'whisper', 'widely',
  'wildlife', 'willing', 'wire', 'wise', 'witness', 'worldwide', 'worth',
  'wound', 'wrap', 'yard', 'youth', 'zone',
];

class SentenceFormationPage extends StatefulWidget {
  const SentenceFormationPage({super.key});

  @override
  State<SentenceFormationPage> createState() => _SentenceFormationPageState();
}

class _SentenceFormationPageState extends State<SentenceFormationPage> {
  int _activeLevel = 1;
  late String _word1;
  late String _word2A;
  late String _word2B;

  @override
  void initState() {
    super.initState();
    _pickRandomWords();
  }

  void _pickRandomWords() {
    final random = Random();
    final list = List<String>.from(_vocabularyWords);
    list.shuffle(random);
    _word1 = _capitalize(list[0]);
    _word2A = _capitalize(list[1]);
    _word2B = _capitalize(list[2]);
  }

  String _capitalize(String word) =>
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: const Navbar(),
      endDrawer: const MobileDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) _buildSidebar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Text('Active Lessons  >  Sentence Formation', style: AppTextStyles.label.copyWith(color: AppColors.bodyGray)),
                        const SizedBox(height: 8),
                        Text('Sentence Formation - Level $_activeLevel', style: AppTextStyles.sectionHeading.copyWith(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text('Build strong, meaningful sentences and improve your communication.', style: AppTextStyles.bodyText.copyWith(color: AppColors.bodyGray)),
                        const SizedBox(height: 24),
                        
                        // Show only the active level card as a sub-page
                        _buildLevelCard(_activeLevel),

                        const SizedBox(height: 32),
                        _buildTechnicalAnalysis(isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('文', style: TextStyle(color: AppColors.primaryRed, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Module 2: Sentence Formation',
                style: AppTextStyles.navLink.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
              ),
              Text(
                'VOCAB & GRAMMAR FOCUS',
                style: AppTextStyles.label.copyWith(color: AppColors.primaryRed, fontSize: 9),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, color: AppColors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.settings, color: AppColors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.category, size: 14, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text('SENTENCE FORMATION', style: AppTextStyles.label.copyWith(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_up, color: AppColors.primaryRed, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Positioned(
                  left: 11,
                  top: 24,
                  bottom: 24,
                  child: Container(
                    width: 2,
                    color: AppColors.primaryRed.withValues(alpha: 0.3),
                  ),
                ),
                Column(
                  children: [
                    _buildLevelNavItem(1, 'Sentence Basics (Level 1)', 'Learn to form at least two meaningful sentences using a single word.'),
                    const SizedBox(height: 24),
                    _buildLevelNavItem(2, 'Sentence Practice (Level 2)', 'Use two given words to form 3-4 meaningful, connected sentences.'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.bar_chart, size: 12, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 6),
              Text('SESSION METRICS', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.bodyGray)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Module Progress', style: AppTextStyles.cardTitle.copyWith(fontSize: 12)),
              Text('40%', style: AppTextStyles.label.copyWith(color: AppColors.primaryRed)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.borderGray,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.4,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildMetric('Accuracy', '88.4'),
          const SizedBox(height: 8),
          _buildMetric('Words Mastered', '12/30'),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
        Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildLevelNavItem(int level, String title, String subtitle) {
    bool isActive = _activeLevel == level;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeLevel = level;
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryRed : AppColors.lightGray,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(level.toString(), style: TextStyle(color: isActive ? AppColors.white : AppColors.bodyGray, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyText.copyWith(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13, color: isActive ? AppColors.charcoal : AppColors.bodyGray)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 10, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryRed : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: active ? AppColors.white : AppColors.charcoal),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.navLink.copyWith(
              color: active ? AppColors.white : AppColors.charcoal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(int level) {
    bool isLevel1 = level == 1;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top row with Icon and Level badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(level.toString(), style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('LEVEL $level', style: AppTextStyles.label.copyWith(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primaryRed.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isLevel1 ? Icons.menu_book : Icons.content_copy, color: AppColors.primaryRed),
          ),
          const SizedBox(height: 16),
          Text(isLevel1 ? 'Sentence Basics (Level 1)' : 'Sentence Practice (Level 2)', style: AppTextStyles.sectionHeading.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            isLevel1 
              ? 'Learn to form at least two meaningful\nsentences using a single word.'
              : 'Use two given words to form 3-4 meaningful,\nconnected sentences.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.bodyGray, fontSize: 13),
          ),
          const SizedBox(height: 24),
          // Vocab section
          if (isLevel1)
             Column(
               children: [
                 Text('YOUR WORD', style: AppTextStyles.label.copyWith(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 _buildWordCardBox(_word1),
               ],
             )
          else
             Column(
               children: [
                 Row(
                   children: [
                     Expanded(child: Column(
                       children: [
                         Text('WORD 1', style: AppTextStyles.label.copyWith(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         _buildWordCardBox(_word2A),
                       ],
                     )),
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 12),
                       child: Container(
                         margin: const EdgeInsets.only(top: 20),
                         width: 28, height: 28,
                         decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                         child: const Icon(Icons.add, color: AppColors.white, size: 16),
                       ),
                     ),
                     Expanded(child: Column(
                       children: [
                         Text('WORD 2', style: AppTextStyles.label.copyWith(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         _buildWordCardBox(_word2B),
                       ],
                     )),
                   ],
                 )
               ],
             ),
             
          const SizedBox(height: 24),
          // Instructions box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primaryRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instructions:', style: AppTextStyles.bodyText.copyWith(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      if (isLevel1) ...[
                        _buildInstructionBullet('Understand the meaning of the word.'),
                        _buildInstructionBullet('Use it in at least two different sentences.'),
                        _buildInstructionBullet('Speak clearly and confidently.'),
                      ] else ...[
                        _buildInstructionBullet('Use both words in your sentences.'),
                        _buildInstructionBullet('Create a logical connection between your ideas.'),
                        _buildInstructionBullet('Speak in 3 to 4 complete sentences.'),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Voice Input Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: VoiceInteractionWidget(
              endpoint: 'vocab-sentence',
              tableName: 'sentence_logs',
              initialPrompt: 'Tap the mic and speak your sentences...',
              extraParams: isLevel1 
                  ? {'word1': _word1, 'word2': ''} 
                  : {'word1': _word2A, 'word2': _word2B},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCardBox(String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(word, style: AppTextStyles.sectionHeading.copyWith(fontSize: 20)),
            ),
          ),
          const Icon(Icons.volume_up, color: AppColors.bodyGray, size: 20),
        ],
      ),
    );
  }

  Widget _buildInstructionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4, height: 4,
            decoration: const BoxDecoration(color: AppColors.charcoal, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.charcoal))),
        ],
      ),
    );
  }

  Widget _buildTechnicalAnalysis(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.terminal, size: 14, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 8),
              Text(
                'TECHNICAL ANALYSIS',
                style: AppTextStyles.label.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildAnalysisMetric('STT_CONFIDENCE', '0.982', const Color(0xFF4ADE80))),
                    Expanded(child: _buildAnalysisMetric('LATENCY_MS', '412', AppColors.white)),
                    Expanded(child: _buildAnalysisMetric('VOCAB_LEVEL', 'C1', AppColors.primaryRed)),
                    Expanded(child: _buildAnalysisMetric('SYNTAX_SCORE', '94/100', AppColors.white)),
                  ],
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildAnalysisMetric('STT_CONFIDENCE', '0.982', const Color(0xFF4ADE80)),
                    _buildAnalysisMetric('LATENCY_MS', '412', AppColors.white),
                    _buildAnalysisMetric('VOCAB_LEVEL', 'C1', AppColors.primaryRed),
                    _buildAnalysisMetric('SYNTAX_SCORE', '94/100', AppColors.white),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildAnalysisMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.white.withValues(alpha: 0.5),
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.sectionHeading.copyWith(
            fontSize: 28,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGray)),
        color: AppColors.white,
      ),
      child: Center(
        child: Text(
          'SYSTEM STATE: READY  |  NODE: V2.4.1-ALPHA',
          style: AppTextStyles.label.copyWith(color: AppColors.bodyGray, fontSize: 10),
        ),
      ),
    );
  }
}

