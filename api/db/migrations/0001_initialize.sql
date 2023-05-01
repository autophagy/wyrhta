CREATE TABLE projects (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    image_key TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
);

CREATE TABLE states (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

INSERT INTO states (id, name) VALUES
    (1, 'Thrown'),
    (2, 'Trimming'),
    (3, 'Awaiting Bisque Firing'),
    (4, 'Awaiting Glaze Firing'),
    (5, 'Finished'),
    (6, 'Recycled');

CREATE TABLE clays (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    shrinkage REAL NOT NULL
);

INSERT INTO clays (name, description, shrinkage) VALUES
    ('White', 'Usually quite soft and not very groggy. Goes to an off-white/creme colour after firing.', 0.08),
    ('Speckled', 'After glaze firing, finishes to a light brown with dark brown spots speckled throughout.', 0.07),
    ('Red', 'A little groggier than white/speckled, usually. After glaze firing goes a dark red-brown.', 0.11),
    ('Black', 'Usually very groggy and rough. After firing goes dark black, usually with a rough surface texture if unglazed.', 0.05);

CREATE TABLE works (
    id INTEGER PRIMARY KEY,
    project_id INTEGER,
    name TEXT NOT NULL,
    notes TEXT,
    clay_id INTEGER,
    glaze_description TEXT,
    image_key TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
    FOREIGN KEY (project_id) REFERENCES projects (id),
    FOREIGN KEY (clay_id) REFERENCES clays (id)
);

CREATE TABLE events (
    id INTEGER PRIMARY KEY,
    work_id INTEGER NOT NULL,
    previous_state INTEGER,
    current_state INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
    FOREIGN KEY (work_id) REFERENCES works (id),
    FOREIGN KEY (previous_state) REFERENCES states (id),
    FOREIGN KEY (current_state) REFERENCES states (id)
);
