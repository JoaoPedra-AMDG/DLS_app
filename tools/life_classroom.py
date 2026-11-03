"""Brief, independently worded summaries of reviewed Life Sciences class files.

Source IDs identify the actual reviewed copies, not merely matching filenames.
Append cards so existing device ratings retain their original card indices.
"""

CELL = '1xKs-JNV6RQSh0yGYCB_8kAD9hGDGyGjj'
CELL_MEMO = '1tt1Vh8-PowIefoNzJQTj2tfu6ixjLx2w'
TISSUES = '10_Z_pIbq_JQXw8NfxmSzI9yauxG0pPqM'
TISSUE_MEMO = '1vMLdJea9mLdDtoHvad3N3gMSvIXLKUII'
MITOSIS = '1CG0dHYqnmZnh0biP6p59NifhTQHZgdvp'
MITOSIS_NOTES = '1E_Ocw-Hhai1Yx64O2xyAcHrwwdag7qBJ'
MITOSIS_MEMO = '11t47y-kXPaQyTGbOBCBjiM1XKFdbXekX'
LIPIDS = '1TfRkYY_6rkxRUsFCBiXzIvjwJCRzDkcw'
PROTEINS = '1sufrDG1utz9s1EJbkuMzNpBvikgXxHl4'
CARBS = '1fLBXAcfAVp0WQjX3LXZBHEf0-M24r03f'
NUTRITION = '1I9PlFLVnF-St-Ah_fO5nDEqK3h9SU9Vp'
RESPIRATION = '1OMOYXNA_pu6B3uvF6jDwJfCXlHPhqvwF'
RESPIRATION_WORKSHEET = '1wv6O9MVMhGJtRyso-zsTbiph1QpFD926'
RESPIRATION_MEMO = '1PHCCprvwQXdFhimGMg6FBj_IaXs1GbT6'
TRANSPORT = '1ibFod84zdV4bsLYGi8Z2kXxfdR4VbhFZ'
TERMS = '1gQ02HhSrpYh7OwgVmsUoqqzdx2SvZ56H'
LONG_QUESTIONS = '1-qbloE3wE84sCLle6gH-k-tq1eiTefC5'
ECOLOGY = '1LT6Z73SNk_qrubSyhG40a93oVuhjzMY8'
INTERACTIONS = '1heJ8k6ia_Bjrjw_QxoSCUFWPIul9nudu'
PYRAMIDS = '1cQHJgufmsyEKJmvKXPpmmxxTux9Btqc3'
CYCLES = '1_0BkJ1VfjMY57ZbtF6Ci4JVp7E_cHZ8d'
HISTORY = '1tubMKr-VNLtN8a2cH6ZmjTzjaToRETEb'
ESSAYS = '1brzEEefwZ_nuDipATcEO_7vohnVqsg1D'

LIFE_PACKS = {
 'life-cells-membrane-transport': dict(
  sources=[CELL, CELL_MEMO, TISSUES, TISSUE_MEMO],
  notes=[
   ('Class summary: cell structures', 'Cells are the basic units of life and arise from existing cells. The nucleus contains DNA; ribosomes make proteins; rough ER and the Golgi apparatus process and transport them. Mitochondria produce ATP, while chloroplasts carry out photosynthesis. Plant cells also have a cellulose wall and a large permanent vacuole.'),
   ('Class summary: membranes and movement', 'The membrane is a selectively permeable phospholipid bilayer with proteins. Diffusion and facilitated diffusion move substances down a gradient without ATP. Osmosis moves water across a selectively permeable membrane from higher to lower water potential. Active transport requires energy; endocytosis brings material in and exocytosis releases it.'),
   ('Class summary: four animal tissues', 'Epithelial tissue covers and lines surfaces; microvilli increase absorption. Connective tissue supports, binds or transports, with cells in an extracellular matrix: bone, cartilage, tendons and blood are examples. Muscle tissue contracts. Nervous tissue carries impulses through neurons and is supported by glial cells.'),
   ('Class summary: muscle and nerve structure', 'Skeletal muscle is striated and voluntary; smooth muscle is non-striated and involuntary; cardiac muscle is branched, striated and involuntary, with intercalated discs. In a typical neuron, dendrites receive impulses, the cell body contains the nucleus, and the axon carries impulses away. Myelin helps impulses travel rapidly.'),
  ],
  cards=[
   ('How are phospholipids arranged in a cell membrane?', 'Hydrophilic heads face the watery surroundings; hydrophobic tails face inward, forming a bilayer.'),
   ('What is the route of a protein being secreted by a cell?', 'Ribosomes on rough ER → transport vesicles → Golgi apparatus → secretory vesicles → cell membrane.'),
   ('Why do mitochondria have cristae?', 'The folded inner membrane provides more surface area for ATP-producing reactions.'),
   ('What do epithelial microvilli do?', 'Increase surface area for absorption; they do not beat like cilia.'),
   ('Why is blood classified as connective tissue?', 'Its cells are suspended in an extracellular matrix: liquid plasma.'),
   ('Which muscle tissue is voluntary and striated?', 'Skeletal muscle.'),
   ('Which muscle tissue has branching cells and intercalated discs?', 'Cardiac muscle; its contractions are involuntary.'),
   ('What is the usual direction of an impulse through a neuron?', 'Dendrites → cell body → axon → axon terminals.'),
  ]),
 'life-mitosis-the-cell-cycle': dict(
  sources=[MITOSIS, MITOSIS_NOTES, MITOSIS_MEMO],
  notes=[
   ('Class summary: preparation and purpose', 'During interphase a cell grows, performs normal functions and replicates DNA before division. Mitosis divides the nucleus and normally preserves chromosome number. It supports growth, replacement, repair and some forms of asexual reproduction. Bacteria reproduce by binary fission, not mitosis.'),
   ('Class summary: PMAT', 'Prophase: chromosomes condense and the spindle forms. Metaphase: chromosomes line up at the equator. Anaphase: sister chromatids separate to opposite poles. Telophase: two nuclei form as chromosomes decondense. Identify the chromosome arrangement in a diagram before naming the phase.'),
   ('Class summary: division outcomes', 'Cytokinesis divides the cytoplasm: animal cells form a cleavage furrow and plant cells form a cell plate. Mitosis normally produces two genetically identical daughter cells. Meiosis involves two divisions and produces four genetically varied cells with half the original chromosome number.'),
  ],
  cards=[
   ('When does DNA replicate before mitosis?', 'During the S phase of interphase, before mitosis begins.'),
   ('What is the difference between karyokinesis and cytokinesis?', 'Karyokinesis divides the nucleus; cytokinesis divides the cytoplasm.'),
   ('What is the key chromosome arrangement in metaphase?', 'Duplicated chromosomes line up at the cell equator, attached to spindle fibres.'),
   ('What separates in anaphase of mitosis?', 'Sister chromatids; after separation, each is a daughter chromosome.'),
   ('How does plant cytokinesis differ from animal cytokinesis?', 'A plant cell forms a cell plate; an animal cell forms a cleavage furrow.'),
   ('Compare the usual products of mitosis and meiosis.', 'Mitosis: two matching cells with unchanged chromosome number. Meiosis: four varied cells with half the chromosome number.'),
   ('Why is mitosis important for growth and repair?', 'It increases cell number and replaces damaged or worn-out cells while preserving genetic information.'),
   ('What can happen if spindle fibres fail to attach correctly?', 'Chromosomes may be distributed unequally, producing daughter cells with abnormal chromosome numbers.'),
  ]),
 'life-enzymes-biological-molecules': dict(
  sources=[LIPIDS, PROTEINS, CARBS],
  notes=[
   ('Class summary: carbohydrates', 'Monosaccharides include glucose, fructose and galactose. Two monosaccharides form a disaccharide: sucrose = glucose + fructose; lactose = glucose + galactose; maltose = glucose + glucose. Polysaccharides include starch for plant storage, glycogen for animal storage and cellulose in plant cell walls.'),
   ('Class summary: proteins', 'Proteins are amino-acid chains joined by peptide bonds; their folded structure determines function. Examples include enzymes, antibodies, haemoglobin, collagen, actin and myosin. Essential amino acids must come from food because the body cannot make enough of them. Denaturation changes protein shape and can destroy its function.'),
   ('Class summary: lipids', 'A triglyceride contains glycerol and three fatty acids joined by ester bonds. Lipids store energy, insulate and protect organs. Saturated fatty acids have no carbon–carbon double bonds; unsaturated fatty acids have at least one. Phospholipids have two fatty-acid tails and a phosphate-containing head, forming cell membranes.'),
   ('Class summary: enzymes', 'Enzymes are biological catalysts: they speed reactions without being used up. A substrate binds to a specific active site. Temperature and pH affect activity; extreme conditions can denature the enzyme. Low temperature usually slows activity without denaturing it. Enzymes are also used in brewing, baking and detergents.'),
  ],
  cards=[
   ('Which monosaccharides form sucrose, lactose and maltose?', 'Sucrose: glucose + fructose. Lactose: glucose + galactose. Maltose: glucose + glucose.'),
   ('Compare starch, glycogen and cellulose.', 'Starch stores carbohydrate in plants; glycogen stores it in animals; cellulose provides plant cell-wall structure.'),
   ('What are the building blocks and joining bonds of proteins?', 'Amino acids joined by peptide bonds.'),
   ('What makes an amino acid essential in the diet?', 'The body cannot synthesise enough of it, so it must be obtained from food.'),
   ('Why can an enzyme lose activity at high temperature?', 'Denaturation changes its active-site shape, so the substrate no longer binds effectively.'),
   ('Does cooling usually denature an enzyme?', 'No. It usually slows molecular movement and reaction rate; activity can recover on warming.'),
   ('What makes up a triglyceride?', 'One glycerol molecule joined to three fatty acids by ester bonds.'),
   ('How do saturated and unsaturated fatty acids differ?', 'Saturated: no carbon–carbon double bonds. Unsaturated: one or more carbon–carbon double bonds.'),
  ]),
 'life-digestion-blood-glucose-control': dict(
  sources=[NUTRITION, CARBS, LONG_QUESTIONS, TISSUE_MEMO],
  notes=[
   ('Class summary: digestive processes', 'Ingestion takes food in. Mechanical digestion breaks it into smaller pieces; chemical digestion uses enzymes to form absorbable molecules. Absorption transfers nutrients across the gut lining; assimilation uses them in cells. Egestion removes undigested material and differs from excretion of metabolic wastes.'),
   ('Class summary: feeding adaptations', 'Incisors cut, canines tear, and premolars and molars crush or grind. Herbivores generally have longer digestive tracts and fermentation regions for plant fibre; ruminant microbes help digest cellulose. Carnivores generally have shorter tracts. Omnivores have adaptations for a mixed diet. Gut microorganisms also help break down some food components.'),
   ('Class summary: absorption and glucose balance', 'Villi and microvilli increase small-intestine surface area. Digestion reduces carbohydrates to monosaccharides; absorbed sugars travel to the liver. Insulin lowers blood glucose by promoting uptake and storage, while glucagon raises it by promoting liver glycogen breakdown and glucose release. Glycogen is stored mainly in liver and muscle.'),
  ],
  cards=[
   ('How do absorption and assimilation differ?', 'Absorption moves digested nutrients across the gut lining; assimilation uses them in body cells.'),
   ('What do incisors, canines and molars do?', 'Incisors cut; canines tear; premolars and molars crush and grind.'),
   ('Why do many herbivores have long digestive tracts?', 'Plant fibre takes time to process, and specialised regions allow microbial fermentation.'),
   ('Why are microbes important in a ruminant’s rumen?', 'They produce enzymes that digest cellulose, which the animal cannot digest using its own enzymes.'),
   ('How do villi and microvilli improve absorption?', 'They greatly increase the surface area of the small-intestine lining.'),
   ('What is insulin’s main effect on blood glucose?', 'It lowers blood glucose by promoting uptake and storage, including glycogen formation.'),
   ('What is glucagon’s main effect on blood glucose?', 'It raises blood glucose by promoting liver glycogen breakdown and glucose release.'),
   ('What is the gut microbiome?', 'The community of microorganisms in the digestive tract; some aid digestion and help limit harmful microbes.'),
  ]),
 'life-photosynthesis-cellular-respiration': dict(
  sources=[CELL, RESPIRATION, RESPIRATION_WORKSHEET, RESPIRATION_MEMO, TERMS],
  notes=[
   ('Class summary: photosynthesis and respiration', 'Photosynthesis stores light energy in organic molecules; aerobic respiration transfers energy from glucose to ATP. Plants perform both processes and respire by day and night. Chloroplast thylakoid membranes carry out light-dependent reactions; carbon fixation occurs in the stroma. Mitochondria are important sites of aerobic respiration.'),
   ('Class summary: ATP and aerobic stages', 'ATP supplies usable energy for transport, movement and synthesis. Glycolysis occurs in the cytoplasm and gives a net two ATP per glucose. The link reaction and Krebs cycle occur in the mitochondrial matrix; the electron transport chain is on the inner membrane. Oxygen is the final electron acceptor; most ATP comes from oxidative phosphorylation.'),
   ('Class summary: fermentation', 'Without oxygen, fermentation allows glycolysis to continue, yielding a net two ATP per glucose. Yeast produces ethanol and carbon dioxide, useful in brewing and bread-making. Animal cells can produce lactate. Aerobic respiration yields much more ATP; the class slide’s 38-ATP total is a simplified teaching tally, not a universal measured yield.'),
  ],
  cards=[
   ('What is the balanced overall equation for photosynthesis?', '6CO₂ + 6H₂O + light energy → C₆H₁₂O₆ + 6O₂.'),
   ('What is the balanced overall equation for aerobic respiration?', 'C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O, with energy transferred to ATP and released as heat.'),
   ('Where does glycolysis occur, and what is its net ATP yield?', 'In the cytoplasm; net two ATP per glucose.'),
   ('Where do the link reaction, Krebs cycle and electron transport chain occur?', 'Link reaction and Krebs cycle: mitochondrial matrix. Electron transport chain: inner mitochondrial membrane.'),
   ('What is oxygen’s role in aerobic respiration?', 'It is the final electron acceptor in the electron transport chain, helping form water.'),
   ('What are the products of yeast fermentation?', 'Ethanol and carbon dioxide; glycolysis supplies net two ATP per glucose.'),
   ('What is produced during fermentation in animal cells?', 'Lactate; the pathway allows glycolysis to keep supplying a net two ATP per glucose.'),
   ('Do green plants respire at night?', 'Yes. They respire by day and night; photosynthesis requires light.'),
  ]),
 'life-plant-transport-adaptations': dict(
  sources=[TRANSPORT, TERMS, LONG_QUESTIONS],
  notes=[
   ('Class summary: plant tissue roles', 'Meristems contain actively dividing cells. Parenchyma performs storage and other functions; chlorenchyma photosynthesises and aerenchyma contains large air spaces. Collenchyma provides flexible support using living cells with unevenly thickened walls. Sclerenchyma provides rigid support using thick, lignified walls; its cells are usually dead at maturity.'),
   ('Class summary: transport tissues', 'Xylem transports water and mineral ions, mainly upwards, and its lignified walls provide support. Phloem transports organic nutrients from sources to sinks. In a typical stem vascular bundle, xylem is towards the inside and phloem towards the outside; roots and leaves have different arrangements.'),
   ('Class summary: transpiration pathway', 'Water enters root cells by osmosis, passes into xylem and moves to leaves. It evaporates from mesophyll cell surfaces and water vapour diffuses through stomata. Transpiration pull maintains the upward water column; cohesion holds water molecules together and adhesion attracts water to xylem walls.'),
   ('Class summary: controlling water loss', 'Warmth, wind and low humidity generally increase transpiration when stomata are open. Guard-cell turgor regulates stomatal opening. Thick cuticles and fewer or sunken stomata reduce water loss, but restricting stomata also limits carbon dioxide uptake and can reduce photosynthesis.'),
  ],
  cards=[
   ('What is meristematic tissue?', 'Plant tissue containing actively dividing cells, responsible for growth.'),
   ('Compare collenchyma and sclerenchyma.', 'Collenchyma: living cells, unevenly thickened walls, flexible support. Sclerenchyma: lignified walls, usually dead at maturity, rigid support.'),
   ('What does xylem transport?', 'Water and mineral ions, mainly from roots towards leaves; it also supports the plant.'),
   ('What does phloem transport?', 'Organic nutrients such as sucrose from sources to sinks.'),
   ('What are the final two steps of transpiration from a leaf?', 'Water evaporates from mesophyll surfaces; water vapour diffuses out through stomata.'),
   ('How do cohesion and adhesion differ in xylem?', 'Cohesion: attraction between water molecules. Adhesion: attraction between water and xylem walls.'),
   ('How do guard cells control stomata?', 'Changes in guard-cell turgor change the size of the stomatal opening.'),
   ('What is the trade-off when a plant closes its stomata?', 'It reduces water loss but also limits carbon dioxide entry for photosynthesis.'),
  ]),
 'life-ecology-nutrient-cycles-biodiversity': dict(
  sources=[ECOLOGY, INTERACTIONS, PYRAMIDS, CYCLES],
  notes=[
   ('Class summary: ecosystems and interactions', 'Biotic factors are living; abiotic factors are non-living. A habitat is where an organism lives; its niche includes its role and resource use. Competition is for limited resources; predation involves one organism eating another. Mutualism benefits both partners, commensalism benefits one without affecting the other, and parasitism benefits one while harming its host.'),
   ('Class summary: food webs and pyramids', 'Producers form the first trophic level; consumers obtain food from other organisms, and decomposers recycle matter. Food-chain arrows show energy moving from food to consumer. Less energy is available at higher levels: about 10% transfer is a simplified model, not a fixed law. Energy pyramids stay upright; pyramids of numbers or biomass can differ.'),
   ('Class summary: carbon, oxygen and water', 'Photosynthesis removes carbon dioxide and releases oxygen. Feeding transfers carbon through food webs; respiration, decomposition and combustion return carbon dioxide. Oxygen is used in aerobic respiration and combustion. The water cycle links evaporation and transpiration with condensation, precipitation, infiltration and runoff. Matter cycles; energy flows through ecosystems.'),
   ('Class summary: nitrogen cycle', 'Fixation converts atmospheric nitrogen into usable nitrogen compounds. Ammonification returns organic nitrogen to ammonia or ammonium. Nitrifying bacteria form nitrites and then nitrates; plants assimilate nitrogen to build molecules such as proteins. Denitrifying bacteria return nitrogen gas to the atmosphere. Most plants cannot use atmospheric nitrogen directly.'),
  ],
  cards=[
   ('How does a habitat differ from a niche?', 'Habitat: where an organism lives. Niche: its role, resource use and interactions.'),
   ('How do biotic and abiotic factors differ?', 'Biotic factors are living, such as competitors; abiotic factors are non-living, such as temperature and water availability.'),
   ('Compare mutualism, commensalism and parasitism.', 'Mutualism: both benefit. Commensalism: one benefits, the other is unaffected. Parasitism: one benefits and the host is harmed.'),
   ('Which way do arrows point in a food chain?', 'From the organism being eaten towards the consumer, showing energy transfer.'),
   ('Using the 10% model, what follows 8,000 kJ at the producer level?', 'About 800 kJ at primary consumers, then 80 kJ at secondary consumers.'),
   ('How do energy flow and nutrient cycling differ?', 'Energy flows through ecosystems and is dissipated as heat; nutrients are recycled between organisms and the environment.'),
   ('Which processes remove and return atmospheric carbon dioxide?', 'Photosynthesis removes it; respiration, decomposition and combustion return it.'),
   ('Distinguish nitrogen fixation, nitrification and denitrification.', 'Fixation: nitrogen gas to usable compounds. Nitrification: ammonium → nitrite → nitrate. Denitrification: nitrate → nitrogen gas.'),
  ]),
 'life-evolution-climate-scientific-essays': dict(
  title='History of life on Earth',
  aliases=['History of life notes', 'Fossils, geological time and mass extinctions'],
  sources=[HISTORY, ESSAYS],
  notes=[
   ('Class summary: origins and evidence', 'The class slides compare hydrothermal-vent, primordial-soup and panspermia hypotheses. Distinguish a proposed explanation from established evidence: the Miller–Urey experiment formed organic molecules, not living organisms. Fossils preserve remains or traces and provide evidence of past organisms, environments and change through time.'),
   ('Class summary: fossils and geological change', 'In undisturbed sedimentary layers, lower layers are generally older: superposition gives relative age. Index fossils help correlate layers; radiometric dating estimates numerical ages using suitable material. Southern African examples include Australopithecus africanus and Homo naledi. Mass extinctions remove many species; environmental change can then create opportunities for surviving groups.'),
   ('Class summary: a discursive science essay', 'Introduce the issue and context. Develop balanced paragraphs using relevant evidence, scientific terminology and your own explanation. Consider more than one interpretation, then weigh the evidence in a justified conclusion. Separate observations, inferences and opinions; uncertainty should not be presented as a proven fact.'),
  ],
  cards=[
   ('What did the Miller–Urey experiment demonstrate?', 'Organic molecules could form under the tested conditions; it did not create living organisms.'),
   ('What kinds of evidence can fossils preserve?', 'Body remains, impressions or traces such as footprints and burrows.'),
   ('What does superposition tell you about undisturbed sedimentary layers?', 'Lower layers are generally older than the layers above them.'),
   ('How does relative dating differ from radiometric dating?', 'Relative dating orders events; radiometric dating uses radioactive decay to estimate numerical ages of suitable materials.'),
   ('What makes an index fossil useful?', 'It is recognisable, widely distributed and restricted to a relatively short geological time interval.'),
   ('Name two hominin species discussed in the Southern African fossil lesson.', 'Australopithecus africanus and Homo naledi.'),
   ('What is a mass extinction?', 'A geologically rapid, widespread loss of a large proportion of species.'),
   ('What belongs in the conclusion of a discursive Life Sciences essay?', 'A judgement that weighs the main evidence and justifies the conclusion, without introducing unsupported claims.'),
  ]),
 'life-scientific-investigations-practical-skills': dict(
  sources=[RESPIRATION_WORKSHEET, RESPIRATION_MEMO, TISSUE_MEMO, MITOSIS_MEMO],
  notes=[
   ('Class summary: a fair investigation', 'State a testable hypothesis linking the independent variable you change to the dependent variable you measure. Keep relevant other conditions constant and explain each control. Repeat measurements and use an adequate sample to improve reliability. Distinguish a control treatment from a controlled variable.'),
   ('Class summary: seed-respiration evidence', 'Living germinating seeds respire actively; boiled, cooled seeds provide a non-living comparison. Carbon dioxide turns clear limewater milky. Keep seed quantity, temperature and apparatus comparable. Prevent microbial contamination, which could also produce carbon dioxide. These observations support respiration in living seeds rather than merely a change in the apparatus.'),
   ('Class summary: interpreting and presenting results', 'Label graph axes with variables and units; describe the trend using data before explaining it. Calculate a percentage as part ÷ total × 100. In cell-division diagrams, include a title, clear labels and the correct chromosome number. Conclusions must answer the investigation question and stay within the evidence.'),
  ],
  cards=[
   ('What is an independent variable?', 'The factor deliberately changed by the investigator.'),
   ('What is a dependent variable?', 'The response measured to see the effect of the independent variable.'),
   ('How does a control treatment differ from a controlled variable?', 'A control treatment provides a comparison; a controlled variable is a condition kept constant.'),
   ('Why use boiled, cooled seeds in a respiration experiment?', 'They provide a non-living control for comparison with actively respiring germinating seeds.'),
   ('What is the limewater test for carbon dioxide?', 'Clear limewater turns milky when carbon dioxide is present.'),
   ('Why limit microbial contamination in a seed-respiration experiment?', 'Microorganisms could respire and produce carbon dioxide, confusing the source of the result.'),
   ('What percentage is 30 cells out of 225?', '30 ÷ 225 × 100 = 13.3%, rounded to one decimal place.'),
   ('What should accompany a graph’s axis labels?', 'The variable names and appropriate measurement units.'),
  ]),
}


def apply_life_summaries(topics, documents):
    source_documents = {sid: d['id'] for d in documents for sid in d['sourceIds']}
    for topic in topics:
        pack = LIFE_PACKS.get(topic['id'])
        if pack is None:
            continue
        if 'title' in pack:
            topic['aliases'] = [topic['title']] + pack.get('aliases', [])
            topic['title'] = pack['title']
        assert len(pack['cards']) == 8
        references = list(dict.fromkeys(source_documents[sid] for sid in pack['sources']))
        topic['classroomSources'] = list(dict.fromkeys(topic['classroomSources'] + references))
        topic['notes'] = [
            dict(heading=heading, body=body, classroomSummary=True, sourceIds=pack['sources'])
            for heading, body in pack['notes']
        ] + topic['notes']
        topic['cards'].extend(
            dict(front=front, back=back, classroomSummary=True, sourceIds=pack['sources'])
            for front, back in pack['cards']
        )


def write_source_audit(root):
    import json
    reviews = json.loads((root/'docs/life_classroom_sources.json').read_text(encoding='utf-8'))
    reviewed = {s['id']: s for s in reviews}
    index = {s['id']: s for s in json.loads((root/'assets/classroom_source_index.json').read_text(encoding='utf-8'))}
    lines = [
        '# Life Sciences class summaries', '',
        'Brief study summaries and recall cards were independently written after reviewing the visible slide or paragraph text of the class files below. These are generated study aids, not official marking guidelines. The source files remain linked through the school account; this update does not add their original bytes to the public app.', '',
        f'{len(LIFE_PACKS)} existing topics; {sum(len(p["notes"]) for p in LIFE_PACKS.values())} brief summary blocks; {sum(len(p["cards"]) for p in LIFE_PACKS.values())} new short flashcards; {len(reviews)} reviewed source copies.', '',
        'Summary blocks appear before the earlier revision notes. Cards are appended after earlier cards, preserving saved device ratings. Downloaded Office originals and extracted text are retained locally in ignored tmp/. The committed JSON records original-file SHA-256 hashes, reviewed copy IDs, formats and slide/paragraph-section counts.', '',
        '| Topic | Brief summaries | New cards | Reviewed class files |',
        '|---|---:|---:|---|',
    ]
    for topic_id, pack in LIFE_PACKS.items():
        files = '<br>'.join(f'[{reviewed[sid]["name"]}]({index[sid]["url"]})' for sid in pack['sources'])
        lines.append(f'| {topic_id} | {len(pack["notes"])} | {len(pack["cards"])} | {files} |')
    lines += [
        '', '## Scope and corrections', '',
        'The two posted Plant Tissue 2024 slide copies did not load. The plant summary instead uses the readable Transport and transpiration slides, Terminology QUESTION 1 and Grade 10 Long Questions. The 2025 animal-tissue slides and worksheet memorandum were reviewed; the inaccessible 2026 presentation is not claimed as a source. Repeated names do not imply identical contents: the listed source IDs identify the copies actually used.', '',
        'The class materials contain some simplified or inaccurate statements. These summaries distinguish bacterial binary fission from mitosis, avoid describing the heart as a single tissue type, and do not apply plant plasmolysis terminology to red blood cells. Respiration notes identify the 38-ATP figure as the class diagram’s simplified tally rather than a universal cellular yield. The food-pyramid 10% transfer is an approximate model. Clinical treatment and dietary advice in the presentations are outside these brief school revision summaries.', '',
        'See [life_classroom_sources.json](life_classroom_sources.json) for source-copy verification metadata.',
    ]
    (root/'docs/LIFE_SCIENCES_CLASSROOM_AUDIT.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
