ALTER TABLE works
  ADD is_multiple BOOLEAN;

UPDATE works
SET is_multiple = 0;
