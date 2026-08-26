# Data access and redistribution

## Pew Research Center inputs

The synthetic-user notebook records the aggregate values taken from the Pew
Research Center report *Podcasts as a Source of News and Information* (2023).
The repository should cite the report and document every transcribed value.

Source: <https://www.pewresearch.org/journalism/2023/04/18/podcasts-as-a-source-of-news-and-information/>

## Listen Notes metadata

The dissertation used a 500-record US podcast metadata export. The record-level
export is not included in this public repository. It may contain provider data
and contact fields, and its redistribution is governed by the provider's
dataset terms.

Source and terms: <https://www.listennotes.com/podcast-datasets/>

The provider's current Terms of Sale permit publication of analysis and
aggregate statistics derived from the data, but prohibit distributing the
Listen Notes records to third parties. They also request notification if
research based on the data becomes public. Accordingly, this repository
publishes aggregate tables only.

Public repository policy:

- do not commit the raw or cleaned record-level export;
- do not commit email addresses or social/contact URLs;
- publish only aggregate tables and figures that are permitted by the source
  terms;
- provide schema documentation and acquisition instructions instead; and
- keep local data under ignored `data/` directories.

The synthetic listener file is not provider data and is published separately
under `data/synthetic/` because it contains no observed individuals or personal
identifiers.

## Expected local fields

The original pipeline refers to podcast identifiers, a Pew-aligned primary
bucket, sponsorship status, Listen Score, global rank, update frequency, genre
labels and title. The local schema is documented in `DATA_SCHEMA.md`; the
public package intentionally contains only the assessed synthetic listeners
and non-identifying aggregate metadata summaries.
