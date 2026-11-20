-- Set the default billboard timing and transition to match the approved presentation specification.
alter table public.billboard_items
  alter column duration_seconds set default 8,
  alter column transition_effect set default 'fade';
