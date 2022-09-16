%so far just a sketch of what this could look like


%simulate independent assortment
tmp = proj(sln_animal.Genotype & 'animal_id=846','animal_id->female_id','allele_id->female_allele_id','allele_name->female_allele_name')...
    * proj(sln_animal.Genotype & 'animal_id=847','animal_id->male_id','allele_id->male_allele_id','allele_name->male_allele_name');

