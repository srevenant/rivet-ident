The unique key used for tracking migrations is composed from the digits of the filename only.

The process I follow:

* A "base" file is the parent of each schema family.
* Migrations extending beyond the base are use an "ext" token in the filename.
* Extension migrations should have a short lifecycle
* Changes from an extension migration should also be reflected in the "base" migrations, but left commented out.
* After an extension migration is deployed and active on all environments, then it is removed from the repository and the base versions of that migration are enabled (de-commented).
