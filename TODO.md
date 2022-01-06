# database v2 rough draft

## `sl_animal.AnimalSource < dj.Shared`
```
source_id : autoincrement
```
- The `dj.Shared` construct allows multiple tables to use the `source_id`, but prevents them from referring to the same entity

## `sl_animal.AnimalVendor`
```
-> sl_animal.AnimalSource
---
vendor_name
```
## `sl_animal.BreedingPair`
```
-> sl_animal.AnimalSource
---
(male_id) -> sl_animal.Animal
(female_id) -> sl_animal.Animal
```
## `sl_animal.Cage`
```
cage_number
---
-> sl_animal.CageRoom
is_breeding = enum('F','T')
```
- Here cages are statically assigned to a room, but we may want to allow cages to move using a `CageEvent`, particularly if we can make that process easy e.g. through barcode scanning
## `sl_animal.AnimalEventActivateBreedingCage`
This can just be removed. If a cage contains both animals in a breeding pair (or just animals of the opposite sex), we implicitly know it's a breeding cage. If an animal is to be reserved for breeding, but isn't currently breeding, we can assign it to a `Breeding` project. If we ever want to know the dates a breeding cage was active, we can just query the `AssignCage` event.

Also remove `DeactivateBreedingCage` and `RetireAsBreeder`. `SetAsBreeder` and `PairBreeders` are merged into `BreedingPair`

## `sl_animal.AnimalEvent < dj.Shared`
```
event_id : autoincrement
---
-> sl_animal.Animal
-> sl_user.User
event_date
event_time
entry_time
event_notes
```
- The `dj.Shared` construct also provides a handy way to assign the same keys to many different tables while allowing them to be concatenated in a union operation
## `sl_animal.AssignCage`
```
-> sl_animal.AnimalEvent
---
cage_number
reason_for_assignment
```
- We'll want to prevent animals of opposite sex from being assigned to the same cage unless the cage is a breeding cage and the animals are a breeding pair

- We'll also want to prevent adding other animals to breeding cages to avoid ambiguity in genetic origin

## `sl_animal.Background`
```
background_name                             #e.g., c57/b6
---
description
```
## `sl_animal.Animal`
```
animal_id : autoincrement
---
dob : date
sex : enum('M','F')                         # M < F
-> sl_animal.Species
-> sl_animal.Background
-> sl_animal.AnimalSource                   #contains the mother and father, if a breeding pair
```

## `sl_animal.GeneLocus`
```
locus_name 
---
description
```

## `sl_animal.Allele`
```
-> sl_animal.GeneLocus
allele_name
---
is_wildtype = enum('F','T')
description
```

## `sl_animal.Genotype`
```
-> sl_animal.Animal
-> sl_animal.GeneLocus
count                                       # 1 or 2, should be set automatically
---
-> sl_animal.Allele
(source_id) -> [nullable] sl_animal.Animal  # the parent this came from, if known
```
- If heterozygote/homozygote status is unclear, we just insert once. Lack of one (or two) genotypes indicates indeterminant genotype status.
- The idea is that we enter in any information that we have, and the GUI can decide how to represent it (e.g., heterozygous vs. non-carrier, GCaMP/Salsa vs. GCaMP/ROSA, GCaMP<sup>+/-</sup>Salsa<sup>-/+</sup>, GCaMP<sup>+/?</sup>). 
- If known, we will assign the allele to a parent (i.e., `source_id` must be from one of the animal's parents, which we can enforce from `sl_animal.Animal.source.male_id`, e.g.)
## `sl_animal.GenotypeSource`
```
source_name                                 # e.g., in-house, transnetyx, jax, inheritance
---
description
```
- This will be useful additional information in the GUI
## `sl_animal.GenotypeResult < dj.Shared`
```
-> sl_animal.AnimalEvent
-> sl_animal.Genotype
---
-> sl_animal.GenotypeSource
```
- As written, this allows more than 2 genotype results per locus per animal (e.g. if we confirm jax information with an in-house result), but also allows 'orphan' genotypes without any genotype results, which may or may not be desirable
## `sl_animal.InHouseGenotypeResult`
```
-> sl_animal.GenotypeResult
---
-> sl_animal.InHouseGenotype                
well_number
```
- We want to require that the genotype source be in-house
## `sl_animal.InHouseGenotype`
```
genotype_id : auto_increment                # the PCR batch this was run on
---
image : @attachment
```
- Multiple animals and multiple alleles typically run on the same plate
## `sl_animal.CandidateAllele`
```
-> sl_animal.Animal
-> sl_animal.Allele
---
(source_id) -> sl_animal.Animal # the animal imposing the candidacy on this one
```
- If a parent is heterozygous for an allele, the animal is a candidate
- If a parent is homozygous for an allele, the animal is presumed positive on one allele and we will want to insert an allele on the child
- Any time a parent's alleles are added/deleted, candidates should cascade to descendents
- We can also cascade candidates from the child to the parents. This ideally would never happen, since we should be genotyping the parents for all the genes we genotype the children for, but this might be a good way to implement that check. Instead of forcing you to genotype the parents first, they would just appear as candidates, reminding you to genotype them.
- Genotyping the animal for the allele should override the candidate in the GUI, without having to delete the candidacy
