ATTACH TABLE _ UUID '32d91bdd-e665-4d5e-8936-e5bd149cc6c7'
(
    `id` UUID DEFAULT generateUUIDv4(),
    `username` String,
    `sample_date` Date,
    `percentage` Float64,
    `age` UInt8,
    `username_hash` String,
    `folder` String,
    `inserted_at` DateTime DEFAULT now()
)
ENGINE = MergeTree
ORDER BY (inserted_at, username)
SETTINGS index_granularity = 8192
