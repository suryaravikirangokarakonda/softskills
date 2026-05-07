import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── HEADINGS (Clean Sans Serif — Alternative to Calibri) ───

  // Hero heading
  static TextStyle heroHeading = GoogleFonts.sourceSans3(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
    height: 1.0,
    letterSpacing: -1.0,
  );

  // Section heading
  static TextStyle sectionHeading = GoogleFonts.sourceSans3(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
    height: 1.1,
    letterSpacing: -0.5,
  );

  // Mono label for technical feel
  static TextStyle monoLabel = GoogleFonts.firaMono(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryRed,
    letterSpacing: 1.5,
  );

  // Body text
  static TextStyle bodyText = GoogleFonts.sourceSans3(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
    height: 1.6,
  );

  // Button text
  static TextStyle buttonText = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // Card title
  static TextStyle cardTitle = GoogleFonts.sourceSans3(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: -0.2,
  );

  // Nav link
  static TextStyle navLink = GoogleFonts.sourceSans3(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
    letterSpacing: 0.2,
  );

  // Small body text
  static TextStyle bodySmall = GoogleFonts.sourceSans3(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.bodyGray,
    height: 1.6,
  );

  // Label / tag
  static TextStyle label = GoogleFonts.firaMono(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryRed,
    letterSpacing: 1.2,
  );

  // Mono text
  static TextStyle monoText = GoogleFonts.firaMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoal,
    letterSpacing: 0.2,
  );

  // Section heading italic (Updated to be cleaner)
  static TextStyle sectionHeadingItalic = GoogleFonts.sourceSans3(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.normal, // Removed italic
    color: AppColors.black,
    height: 1.15,
    letterSpacing: -0.5,
  );

  // CTA Heading (white, large)
  static TextStyle ctaHeading = GoogleFonts.sourceSans3(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.1,
    letterSpacing: -0.5,
  );

  // Footer text
  static TextStyle footerLink = GoogleFonts.sourceSans3(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.bodyGray,
    height: 2.0,
  );

  // Footer heading
  static TextStyle footerHeading = GoogleFonts.sourceSans3(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    letterSpacing: 0.5,
  );
}

