PODES Merge
===========

https://github.com/travisscassidy/podes-merge

Do-files and crosswalks that merge villages across the Indonesian village
census (Potensi Desa, PODES) waves of 2005, 2008, 2011, 2014, 2018, 2019,
2020, 2021, 2024 and 2025, and with the village population counts of the 2010
population census (SP2010). The package also links BPS village codes to the
village codes of the Ministry of Home Affairs (Kemendagri), which are used in
Dana Desa and village population data.

If you only need village codes and names across years, you do not need PODES
data: use the files in output/ (see section 6).

If you use this code or these files, please cite:

  Cassidy, Traviss, Nurina Merdikawati, and Tejaswi Velayudhan. 2026.
  "Decentralization and Development: Evidence from Indonesia's Village Law."
  Working paper.

For the links before 2005, please also cite:

  Cassidy, Traviss. 2025. "Revenue Persistence and Public Service Delivery."
  Economic Journal, 135 (670): 2017-2053.


1. PODES data
-------------

Raw PODES data may be purchased from BPS at https://silastik.bps.go.id/.
Put each wave in its own subfolder of podes_raw/ (or of any folder; see
section 3), named and containing the files below. These are the file names
of the author's purchase.

  Folder             Files read
  -----------------  ----------------------------------------------------------
  PODES 2005         pod06_a.dbf, pod06_b.dbf, pod06_c.dbf
  PODES 2005 Nias    pds05_n1.dbf, pds05_n2.dbf
  PODES 2008         pds2008_d1_new.dbf ... pds2008_d3_new.dbf
  PODES 2011         podes_desa_2011_d1.dbf ... podes_desa_2011_d3.dbf,
                     podes_nagari_2011_d1.dbf, podes_nagari_2011_d2.dbf,
                     podes_jorong_2011_d1.dbf, podes_jorong_2011_d2.dbf
  PODES 2014         podes_desa_2014_d1_new.dbf ... podes_desa_2014_d3_new.dbf
  PODES 2018         podes2018_desa_part1_revisi.dbf ... part4_revisi.dbf
  PODES 2019         podes_2019_b1b8.dbf, podes_2019_b9b13.dbf
  PODES 2020         podes2020_b1b7.dbf, podes2020_b8b13.dbf
  PODES 2021         podes2021_desa_1.dbf ... podes2021_desa_4.dbf
  PODES 2024         podes2024_desa_01.dbf ... podes2024_desa_04.dbf
  PODES 2025         podes2025-desa_part1.dbf, podes2025-desa_part2.dbf
  PODES 2011 INFR    Optional (World Bank PODES 2011 infrastructure files):
                     Podes11-PoskesdesPolindes.dta, Podes11-PuskesmasPustu.dta,
                     Podes11-Listing Faskesdik 1.dta

If PODES 2011 INFR is absent, the code skips it. The merge is unaffected
(the village codes and names in podes_05_25 are identical either way), but
podes2011.dta then lacks status_2011 (urban/rural) and five health and school
counts (n_schl_voc_pub_2011, n_mwiv_polin_2011, n_dr_pusk_2011,
n_dent_pusk_2011, n_mwiv_pusk_2011).

The BPS village name files (MFD) of 2005, 2008 and 2011 are read from names/,
not from podes_raw/ (see section 5).


2. Folders
----------

  master.do        Sets the paths and runs everything (section 3).
  dofiles_main/    The main do-files, run by master.do in this order:
                   1_clean_district_cross.do district crosswalk 1990-2014
                   2_clean_pop2010.do        SP2010 village population
                   3_clean_podes.do          cleans each PODES wave
                   4_merge_podes.do          builds the village crosswalks
                                             and merges PODES 2005-2025
                   5_link_bps_kemendagri.do  BPS-Kemendagri village codes
                   6_check_merge.do          integrity check of the merge
  dofiles_aux/     Do-files called by the main do-files (name
                   standardization).
  crosswalks/      Village and district crosswalks (section 5). The BPS
                   1998-2013 and 2010-2015 village crosswalks are zipped;
                   4_merge_podes.do unzips them into temp/.
  names/           BPS village names and codes provided with PODES or
                   published by BPS, by wave (section 5).
  census/          SP2010 village population (BPS), xlsx and source PDFs.
  output/          Prebuilt files with codes and names only (section 6).
  podes_raw/       Empty. Put the purchased PODES data here (section 1).

master.do creates two more folders:
  work/            Data built by the do-files (about 3 GB) and master.log.
  temp/            Unzipped crosswalks (about 0.8 GB). Can be deleted after
                   the run.


3. How to run
-------------

Requirements:
  - Stata 16 or later (6_check_merge.do uses frames).
  - reclink2 (Wasi and Flaaen 2015, Stata Journal 15(3), package dm0082).
    master.do installs it if it is missing:
      net install dm0082, from("http://www.stata-journal.com/software/sj15-3")

Steps:
  1. Open master.do and set two globals:
       global root       the folder that contains master.do
       global podes_raw  the folder with the PODES wave subfolders
                         (default: $root/podes_raw)
  2. Run master.do. On a desktop computer the full run takes about 15
     minutes.

The main output is work/podes_05_25.dta: one row per village lineage, with
the codes and names of every year and the data of every PODES wave. Other
files in work/: podesYYYY.dta (each wave), pop2010.dta, cross_*.dta (village
crosswalks), district_cross_1990_2014.dta, cross_bps_kemendagri_2020.dta, and
the reports of the integrity check (check_*.dta, check_*.csv).


4. How the merge works
----------------------

Unit of observation: one row per village lineage. A lineage follows a village
through BPS's code changes. When a village splits, each new village gets its
own row, and the rows of the new villages repeat the codes, names and PODES
records of the parent village in the years before the split. Records are
therefore repeated across rows (see "Rows holding" below); no record is lost
(see the integrity check below).

The merge links each wave to the BPS crosswalks by village code and name,
then uses the author's manual crosswalks (crosswalks/manual_podes/) where the
official crosswalks are missing or wrong, and fuzzy name matching (reclink2)
for the remaining PODES 2005 and 2008 villages.

Integrity check (6_check_merge.do). It identifies each record of each wave by
its content and asserts that (a) every record of every wave appears in
podes_05_25 and (b) no row combines data from two records of the same wave.
It then reports rows that hold one wave only, rows whose name in a wave
differs from the name of the record they hold, and codes shared by rows with
different names.

Match rates (author's run). A record is "linked" if its row also holds a
record of at least one other wave.

  Wave     Records   Rows holding   Linked records   Share linked
  -------  -------   ------------   --------------   ------------
  2005      70,612         84,690           70,503          99.8%
  2008      75,410         85,390           75,370          99.9%
  SP2010    77,084         85,468           77,062         100.0%
  2011      78,609         85,510           78,508          99.9%
  2014      82,190         85,510           82,162         100.0%
  2018      83,931         85,539           83,931          100%
  2019      83,937         85,547           83,937          100%
  2020      84,038         85,545           84,038          100%
  2021      84,096         85,547           84,096          100%
  2024      84,276         85,548           84,276          100%
  2025      84,139         85,387           84,139          100%

podes_05_25 has 85,931 rows. 84,114 rows hold a record of all 11 waves.
The 2005 records include PODES 2005 Nias (656 villages).


5. Sources of the crosswalks and name files
-------------------------------------------

  File or folder                          Source
  --------------------------------------  -------------------------------------
  crosswalks/village_crosswalk_1998_2013  BPS (official village crosswalk)
  crosswalks/village_crosswalk_2010_2015  BPS
  crosswalks/village_crosswalk_2013_2018  BPS
  crosswalks/village_crosswalk_2014_2021  BPS (including the 2019-2021
                                          village hierarchy files)
  crosswalks/village_crosswalk_2021_2024  BPS (panel MFD 2021-2024)
  crosswalks/mfd_2024_sem2                BPS village master file, 2024
                                          semester 2
  crosswalks/manual_podes                 Author (manual corrections and
                                          links between PODES waves)
  crosswalks/district_proliferation       World Bank INDO-DAPOER District
                                          Proliferation Crosswalk (district
                                          codes and names by year), revised
                                          and extended to 2014 by the author.
                                          1_clean_district_cross.do builds
                                          work/district_cross_1990_2014.dta
                                          from it; 3_clean_podes.do uses it
                                          for the 1998-2005 district codes
                                          of the PODES 2005 villages
  crosswalks/bps_kemendagri               BPS-Kemendagri code correspondence,
                                          downloaded from BPS
                                          (sig.bps.go.id, see Source.txt);
                                          manual_cross_kb_vlg.xlsx and
                                          corrections_cross_kb_vlg.xlsx by the
                                          author
  crosswalks/manual_moha                  Author (links between years of the
                                          Kemendagri village codes in Dana
                                          Desa and population data, and
                                          between PODES and those data). Not
                                          used by the do-files; included for
                                          users of Kemendagri codes
  names/PODES 2005, 2008, 2011, 2014      BPS name files (MFD) provided with
                                          PODES
  names/PODES 2005 Nias                   BPS name files provided with PODES
  names/PODES 2018 ... 2021               BPS master region files of PODES
  names/PODES 2024                        BPS name file provided with PODES
  names/PODES 2025                        Extract of the codes and names in
                                          the PODES 2025 village file (no
                                          other PODES variables)
  census/                                 BPS, SP2010 village population
                                          (see Source.txt)

Why names/ is included: new purchases of some PODES waves may lack village
names, although BPS used to provide them.


6. Prebuilt files (output/)
---------------------------

output/output_csv.zip holds five .csv files with codes and names only. They
contain no PODES survey variables and no Dana Desa or population figures.
Run output/import_output.do (set the folder at its top) to unzip them and
save each as .dta.

  podes_lineage_2005_2025   85,931 rows, one per row of podes_05_25.
      in_YYYY               1 if the row holds the YYYY record (2005, 2008,
                            2010 = SP2010, 2011, 2014, 2018, 2019, 2020,
                            2021, 2024, 2025)
      idYYYY, nmYYYY        BPS village code (10 digits) and name in year
      idYYYY_1, idYYYY_2    YYYY; _1 and _2 are BPS semester 1 and 2
      nmYYYY_1, nmYYYY_2    (the codes change between semesters); see the
                            note below for 2005, 2008, 2010 and 2011
      id_podesYYYY,         code and name exactly as in the raw PODES file
      nm_podesYYYY          of wave YYYY; use these to merge PODES
                            variables of that wave to the lineage (below)
      bps_YYYY              4-digit district (kabupaten/kota) code
      province_YYYY,        names of the province, district, district type
      region_YYYY,          and subdistrict (kecamatan) in wave YYYY
      region_type_YYYY,
      kec_YYYY, desa_YYYY
  cross_1998_2024           The village crosswalk 1998-2024 built by
                            4_merge_podes.do (85,671 rows).
  cross_2024_2025           The village crosswalk 2024-2025 (84,139 rows).
  cross_bps_kemendagri_2020 BPS (kode_bps) and Kemendagri (kode_dagri)
                            village codes and names, 2020 semester 2, with
                            province, district and subdistrict codes and
                            names of both (83,429 rows; kode_dagri unique).
  moha_lineage_2016_2025    Kemendagri village codes and names 2016-2025
                            (id_kd_YYYY, desa_YYYY) with kode_bps, from the
                            author's merge of Dana Desa and village
                            population data (83,193 rows). Join to the PODES
                            lineage on kode_bps = id2020_1 (or id2020_2):
                            83,117 of the 83,120 BPS codes are found.

Codes of 2005, 2008, 2010 and 2011: where the BPS crosswalk code of a row
differs from the code of the PODES (or SP2010) record the row holds,
idYYYY / idYYYY_1 and nmYYYY / nmYYYY_1 are the record's code and name. The
BPS crosswalk codes themselves are in cross_1998_2024.

Merging PODES data to the lineage: id_podesYYYY is the village code of the
raw PODES file of wave YYYY, so users with the PODES data can attach any
PODES variable of that wave with merge m:1 id_podesYYYY (several rows can
hold the same record: split villages repeat their parent's record). Only
rows that hold the record (in_YYYY == 1) have id_podesYYYY.

Text cleaning in output/ only: line breaks inside names (in the raw sources)
were replaced by spaces, and one invalid character in a PODES 2005 name was
replaced by an apostrophe. Some Kemendagri names write an apostrophe as a
double quote (e.g. SOKA"AN); these were kept.


7. Known limitations
--------------------

- Village codes are not unique within a year: split villages share the
  parent's codes in earlier years, and a few codes are shared by different
  villages in the BPS crosswalks (reported by 6_check_merge.do, Part 3).
- A small number of records are not linked to any other wave (section 4):
  109 PODES 2005, 40 PODES 2008, 22 SP2010, 101 PODES 2011 and 28 PODES 2014
  records. The lists are in work/check_onewave.csv.
- Kemendagri codes: 73 of the 83,193 rows of moha_lineage_2016_2025 have no
  BPS code (51 of them in the Papua provinces).
- Codes and names follow BPS and Kemendagri as published; errors in those
  sources may remain.


8. License and disclaimer
-------------------------

The do-files are released under the MIT License (LICENSE). The author's
crosswalks (crosswalks/manual_podes, crosswalks/manual_moha, the author's
revisions in crosswalks/district_proliferation, and manual_cross_kb_vlg.xlsx
and corrections_cross_kb_vlg.xlsx in crosswalks/bps_kemendagri) and the files
in output/ are released under the Creative Commons Attribution 4.0
International License (CC BY 4.0, LICENSE-DATA); please cite the papers
above.

The crosswalks and name files from BPS, Kemendagri and the World Bank are
redistributed for research use and are not covered by these licenses; their
copyright remains with the original sources.

The files are provided as is, without warranty. Report problems to the
author or open an issue on GitHub.
