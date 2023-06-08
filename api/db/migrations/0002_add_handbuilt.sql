-- Update `states` table
UPDATE states SET id = id + 1 WHERE id == 6;
UPDATE states SET id = id + 1 WHERE id == 5;
UPDATE states SET id = id + 1 WHERE id == 4;
UPDATE states SET id = id + 1 WHERE id == 3;

-- Insert new state 'Handbuilding' with id 3
INSERT INTO states (id, name)
VALUES (3, 'Handbuilding');

-- Update `events` table to reflect changes in `states` table
UPDATE events
SET previous_state = previous_state + 1
WHERE previous_state IS NOT NULL AND previous_state >= 3;

UPDATE events
SET current_state = current_state + 1
WHERE current_state >= 3;
