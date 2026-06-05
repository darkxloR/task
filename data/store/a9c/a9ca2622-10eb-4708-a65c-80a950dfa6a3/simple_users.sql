ATTACH TABLE _ UUID '4fea34ae-fabc-4e0a-b408-d533b8f1b620'
(
    `username` String,
    `date` Date,
    `percentage` Float64,
    `age` UInt8,
    `hash` String
)
ENGINE = MergeTree
ORDER BY username
SETTINGS index_granularity = 8192
