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

Public repository policy:

- do not commit the raw or cleaned record-level export;
- do not commit email addresses or social/contact URLs;
- publish only aggregate tables and figures that are permitted by the source
  terms;
- provide schema documentation and acquisition instructions instead; and
- keep local data under ignored `data/` directories.

## Expected local fields

The original pipeline refers to podcast identifiers, a Pew-aligned primary
bucket, sponsorship status, Listen Score, global rank, update frequency, genre
labels and title. The corrected-analysis release will add an explicit schema
and validation script before any public data example is supplied.

