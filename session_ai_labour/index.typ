// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
#show: doc => article(
  title: [Gen-AI and the Labour Market],
  authors: (
    ( name: [Pablo Winant],
      affiliation: [],
      email: [] ),
    ),
  date: [2024-01-29],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)
#import "@preview/fontawesome:0.1.0": *


== 
<section>
#block[
#figure([
#box(width: 200.0pt, image("cnn.png"))
], caption: figure.caption(
position: bottom, 
[
News
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
. . .

From CNN: #emph['Jobs may disappear': Nearly 40% of global employment could be disrupted by AI, IMF says]

. . .

🤔 How do they know that?

. . .

Check out the #link("document.pdf")[docuements]

= Introduction
<introduction>
== 
<section-1>
#block[
#callout(
body: 
[
Find some context about the study and the various authors implicated.

Why is IMF interested in AI?

]
, 
title: 
[
Task
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
)
]
== IMF & AI: a recent stream of activity
<imf-ai-a-recent-stream-of-activity>
#block[
- #link("https://www.imf.org/en/Blogs/Articles/2024/01/14/ai-will-transform-the-global-economy-lets-make-sure-it-benefits-humanity")[Blog Post];. written by Kristalina Goeorgieva Head of IMF
- #link("https://www.imf.org/en/Publications/Staff-Discussion-Notes/Issues/2024/01/14/Gen-AI-Artificial-Intelligence-and-the-Future-of-Work-542379?cid=bl-com-SDNEA2024001")[Staff Discussion Note];: by Cazzaniga et al.~validated by Pierre-Olivier Gourinchas, Head of Research
- #link("https://www.imf.org/en/Publications/WP/Issues/2023/10/04/Labor-Market-Exposure-to-AI-Cross-country-Differences-and-Distributional-Implications-539656")[IMF Working Paper];: #emph[Labor Market Exposure to AI: Cross-country Differences and Distributional Implications] by Pizzinelli et al.~

]
. . .

Blog also points to:

- #link("https://www.imf.org/en/Publications/fandd/issues")[IMF F&D December]

- #link("https://www.nber.org/papers/w31161")[Generative AI at Work]

Many other referencs in the SDN.

== How Research is done at IMF
<how-research-is-done-at-imf>
#block[
#block[
#block[

#block[
#box(width: 10.67in, image("index_files/figure-typst/mermaid-figure-1.png"))

]

]
]
]
How does it impact what you read?

== Research in Big Institutions
<research-in-big-institutions>
The #emph[publication] of research papers in big international institutions has several goals:

#block[
- disseminate research
  - usually from researchers that are closest to policy circles
- build a common narrative that countries can build on to negociate with the same language
  - provide a discussion forum when there isn’t one
- \(usually not) state an official position of the institution

]
== Example of Shaping the Narrative
<example-of-shaping-the-narrative>
Bank of England, communicates on forward guidance:

- delphic vs odyssean forward guidance

. . .

Andy Haldane, chief economist:

#image("maradona.jpg")

== 
<section-2>
#block[
#callout(
body: 
[
The IMF is a global organization that works to achieve sustainable growth and prosperity for all of its 190 member countries. It does so by supporting economic policies that promote financial stability and monetary cooperation, which are essential to increase productivity, job creation, and economic well-being. The IMF is governed by and accountable to its member countries.

]
, 
title: 
[
About the IMF
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
)
]
. . . Then why is it interested in AI?

. . .

Check out #link("https://www.imf.org/en/About/Factsheets/IMF-Lending")[the webpage]

== Why is IMF interested in AI?
<why-is-imf-interested-in-ai>
#block[
+ IMF lends in times of crisis

- it is useful to know what might cause the next one \(CoVid2, AI, food shortage, global warning…)

#block[
#set enum(numbering: "1.", start: 2)
+ It pushes for structural reforms \(but which ones?)
]

- so that countries can reimburse loans

#block[
#set enum(numbering: "1.", start: 3)
+ It sometimes act as a last-resort multilateral institution
]

- where do all finance ministers sit down to discuss …?

]
= What is it exactly that you do? Can AI do your job?
<what-is-it-exactly-that-you-do-can-ai-do-your-job>
== 
<section-3>
#block[
#callout(
body: 
[
Check out the O\*NET database.

What is the difference between a skill, an abilty, …

What part occupational content is more relevant to judge AI exposure?

]
, 
title: 
[
Question 2
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
)
]
== 
<section-4>
#box(width: 1298.0pt, image("assets/onet.png"))

== O\*NET
<onet>
#block[
- Conceptual framework: O\*NET content model

  - an occupation \(a job) is associated to a particular content \(skills, abilities, tasks, activities, context)
  - some content relates to the worker, some to the nature of the occupation
  - data comes from incumbant and experts

]
== How can you measure AI fitness for a job?
<how-can-you-measure-ai-fitness-for-a-job>
Which content is more relevant to judge AI fitness?

- skills
- abilities
- tasks

A growing body of literature \(led by Autor , Levy, Murnane 2003) is using content of jobs to assess the potential effect of new technologies.

== Earlier work has focused on tasks
<earlier-work-has-focused-on-tasks>
Earlier work has focused on tasks.

- … for automation
- … for machine learning

== Example
<example>
#emph[What Can Machines Learn and What Does It Mean for Occupations and the Economy?];, 2018 Erik Brynjolfsson, Tom Mitchell, and Daniel Rock

From O\*NET database \(occupational information)

- 964 #emph[occupations] ,decomposed 18,156 #emph[tasks]
- Tasks agggregated into of 2,069 work activities
  - ex: sort information, show empathy

Use human judgment to measure the suitability for machine learning of each task.

== Human Judgment
<human-judgment>
#image("assets/mturk.webp")

. . .

In practice, human judgment is replaced with Amazon Turk or CrowdFlower

== Example: Result
<example-result>
#box(height: 100%,image("assets/result__occupations.png"))

== Example: Result \(2)
<example-result-2>
#box(width: 100%,image("assets/result__distribution.png"))

== Examples: Conclusions
<examples-conclusions>
Almost no

- fully replaceable occupation
- fully ML immune occupation

All the distribution of income exposed.

The results are typical from the literature.

== Abilities
<abilities>
IMF Paper looks at #strong[abilities]

Paper builds on #emph[Occupational, industry, and geographic exposure to artificial intelligence: A novel dataset and its potential uses];, by Felten, Raj, and Seamans 2021.

Main idea: try to assess the adequacy of AI for each ability.

== Construct AI suitability index
<construct-ai-suitability-index>
AI exposure of ability $k$:

$ A I E O_k = sum_j L_(k j) A I_j $

where:

- $L_(k j)$: ability content of task $k$
- $A I_j$: suitability of $j$ for ability $j$

. . .

How do we measure AI abilities?

== 
<section-5>
#image("assets/eff.svg")

The Electronic Frontier Foundation \(EFF) is a well-regarded digital rights nonprofit that was founded in 1990,

As one of its activities, the EFF collects and maintains statistics about the progress of AI across separate artificial intelligence applications.

Each AI application has an index corresponding to AI development.

== EFF application definitions
<eff-application-definitions>
#figure(
align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [AI application], [Definition],
  [Abstract strategy games],
  [The ability to play abstract games involving sometimes complex strategy and reasoning ability, such as chess, go, or checkers, at a high level.],
  [Real-time video games],
  [The ability to play a variety of real-time video games of increasing complexity at a high level.],
  [Image recognition],
  [The determination of what objects are present in a still image.],
  [Visual question answering],
  [The recognition of events, relationships, and context from a still image.],
  [Image generation],
  [The creation of complex images],
  [Reading comprehension],
  [The ability to answer simple reasoning questions based on an understanding of text.],
  [Language modeling],
  [The ability to model, predict, or mimic human language.],
  [Translation],
  [The translation of words or text from one language into another.],
  [Speech recognition],
  [The recognition of spoken language into text.],
  [Instrumental track recognition],
  [The recognition of instrumental musical tracks.],
)]
)

== Mapping EFF application definitions to ONET abilities
<mapping-eff-application-definitions-to-onet-abilities>
Human Judgment \(mturk) is used to associate each each of the $l in [1 , 10]$ EFF application to the $j in [1 , 51]$ O\*NET categories: $x_(l , j)$

In practice, human judgment come from `mturk`.

AI suitability for ability $j$ is then defined as $ A I_j = sum_(l = 1)^10 x_(l , j) $

= Or will it work for you?
<or-will-it-work-for-you>
== 
<section-6>
#block[
#callout(
body: 
[
How does the SDN distinguishes between jobs that are more or less complement to AI. What are the contexts ? How is the complementarity score computed?

]
, 
title: 
[
Question 3
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
)
]
== Complementarity-augmented AI-exposure
<complementarity-augmented-ai-exposure>
The main contribution from the Pizzilnelli et al.~paper : use more content from O\*NET:

- work context: \*physical and social factors that influence the nature of work
- job zones: groups of occupations characterized by similar levels of education, on-the-job training, and professional experience needed to perform the work

Some contexts #emph[shield] workers from being replaced by AI

== 
<section-7>
Each O\*NET occupation is associated with each of the following context by a 0-100 score:

- Communication
- Responsibility
- Physical Conditions
- Criticality
- Routine
- Skills

. . .

The final complementarity score is the average of all contexts, normalized to be between 0 and 1.

== Complementarity measure
<complementarity-measure>
#box(width: 644.0pt, image("assets/complementarity.png"))

== Exposure / Complementarity
<exposure-complementarity>
#box(width: 770.0pt, image("assets/exposure_complementarity.png"))

== Comments?
<comments>
= Who will be affected ? Who will win / loose ?
<who-will-be-affected-who-will-win-loose>
== 
<section-8>
#block[
#callout(
body: 
[
According to the article who is most likely to be affected?

What would be the effect on inequalities?

Which countries will suffer most?

]
, 
title: 
[
Question 4
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
)
]
== Within a Country
<within-a-country>
#box(width: 957.0pt, image("assets/loosers_winners.png"))

== Dynamics
<dynamics>
The behaviour of top earners is crucial:

AI will increase inequalities increase if:

- top earners are \(comparatively) less exposed

Social Mobility is important

== 
<section-9>
#box(width: 1251.0pt, image("assets/transition.png"))

== Across Countries
<across-countries>
#block[
]
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#box(width: 100%,image("assets/ai_exposure.png"))

],
  rect(stroke: none, width: 100%)[
#box(width: 100%,image("assets/ae_advantage.png"))

],
)
== AI preparedness Index
<ai-preparedness-index>
#box(width: 586.0pt, image("assets/preparedness.png"))

= Conclusion
<conclusion>
== Conclusion?
<conclusion-1>



