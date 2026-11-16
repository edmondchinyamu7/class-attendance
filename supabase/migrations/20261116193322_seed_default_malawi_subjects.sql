-- Seed the standard Malawi secondary-school subject catalogue for schools
-- that already exist. Preserve school-specific extra subjects and all history.
DO $$
DECLARE
  school_record record;
BEGIN
  FOR school_record IN SELECT id FROM public.schools LOOP
    IF EXISTS (
      SELECT 1 FROM public.school_subjects
      WHERE school_id = school_record.id AND lower(subject_name) = 'mathematics'
    ) AND NOT EXISTS (
      SELECT 1 FROM public.school_subjects
      WHERE school_id = school_record.id AND lower(subject_name) = 'maths'
    ) THEN
      UPDATE public.school_subjects
      SET subject_name = 'Maths'
      WHERE school_id = school_record.id AND lower(subject_name) = 'mathematics';
    END IF;
  END LOOP;
END $$;

INSERT INTO public.school_subjects (school_id, subject_name, is_active)
SELECT s.id, defaults.subject_name, true
FROM public.schools s
CROSS JOIN (VALUES
  ('English'),
  ('Maths'),
  ('Chichewa'),
  ('Bible Knowledge'),
  ('Physics'),
  ('Chemistry'),
  ('Social Studies'),
  ('Agriculture'),
  ('Biology'),
  ('Geography'),
  ('History')
) AS defaults(subject_name)
ON CONFLICT (school_id, subject_name) DO NOTHING;
