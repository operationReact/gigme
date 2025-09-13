-- Add basic indexes to improve prefix search performance on ~10k rows
CREATE INDEX IF NOT EXISTS idx_fp_display_name ON freelancer_profiles(display_name);
CREATE INDEX IF NOT EXISTS idx_fp_prof_title ON freelancer_profiles(professional_title);
CREATE INDEX IF NOT EXISTS idx_fp_skills ON freelancer_profiles(skillsCsv);

