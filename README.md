# Epi-Info-Community-Edition

## Sobre este fork (Português)

Este é um fork mantido internamente, criado em 2026-08-07 a partir do
repositório oficial do CDC ([`Epi-Info/Epi-Info-Community-Edition`](https://github.com/Epi-Info/Epi-Info-Community-Edition)),
porque a manutenção oficial do Epi Info 7 pelo CDC ficou muito mais lenta —
o repositório upstream está sem commits desde 2025-04-09. O objetivo é
continuar operando e corrigindo o software sem depender de novas
atualizações do CDC.

Mudanças feitas neste fork até agora:
- **Correção de 2 vulnerabilidades conhecidas**: `SharpCompress` (0.32.2 → 0.48.0, GHSA-6c8g-7p36-r338) e `Snappier` (1.0.0 → 1.3.1, GHSA-pggp-6c3x-2xmx).
- **Correção de build**: desativada a geração de manifesto ClickOnce do módulo `Enter`, que apontava para infraestrutura interna do CDC e travava a compilação fora da rede deles.

Licenciado sob a mesma Apache License 2.0 do projeto original — ver
[`license.md`](license.md). Histórico completo de decisões e ações em
`RUNBOOK.md` no repositório do projeto principal (não versionado aqui).

## About this fork (English)

This is an internally maintained fork, created on 2026-08-07 from the
official CDC repository ([`Epi-Info/Epi-Info-Community-Edition`](https://github.com/Epi-Info/Epi-Info-Community-Edition)),
because the CDC's official maintenance of Epi Info 7 has slowed down
considerably — the upstream repository has had no commits since
2025-04-09. The goal is to keep operating and fixing the software
without depending on new updates from the CDC.

Changes made in this fork so far:
- **Fixed 2 known vulnerabilities**: `SharpCompress` (0.32.2 → 0.48.0, GHSA-6c8g-7p36-r338) and `Snappier` (1.0.0 → 1.3.1, GHSA-pggp-6c3x-2xmx).
- **Build fix**: disabled ClickOnce manifest generation for the `Enter` module, which pointed at internal CDC infrastructure and broke the build outside their network.

Licensed under the same Apache License 2.0 as the original project —
see [`license.md`](license.md). Full history of decisions and actions
lives in `RUNBOOK.md` in the main project repository (not versioned here).

## Acerca de este fork (Español)

Este es un fork mantenido internamente, creado el 2026-08-07 a partir
del repositorio oficial del CDC ([`Epi-Info/Epi-Info-Community-Edition`](https://github.com/Epi-Info/Epi-Info-Community-Edition)),
porque el mantenimiento oficial del Epi Info 7 por parte del CDC se ha
vuelto mucho más lento — el repositorio upstream no tiene commits desde
el 2025-04-09. El objetivo es seguir operando y corrigiendo el software
sin depender de nuevas actualizaciones del CDC.

Cambios realizados en este fork hasta ahora:
- **Corrección de 2 vulnerabilidades conocidas**: `SharpCompress` (0.32.2 → 0.48.0, GHSA-6c8g-7p36-r338) y `Snappier` (1.0.0 → 1.3.1, GHSA-pggp-6c3x-2xmx).
- **Corrección de compilación**: se desactivó la generación del manifiesto ClickOnce del módulo `Enter`, que apuntaba a infraestructura interna del CDC y bloqueaba la compilación fuera de su red.

Licenciado bajo la misma Apache License 2.0 del proyecto original — ver
[`license.md`](license.md). El historial completo de decisiones y
acciones está en `RUNBOOK.md`, en el repositorio del proyecto principal
(no versionado aquí).

---

**Epi Info™ for Windows Download**
https://www.cdc.gov/epiinfo/pc.html

Epi Info™ is a public domain suite of interoperable software tools designed for the global community of public health practitioners and researchers. It provides for easy data entry form and database construction, a customized data entry experience, and data analyses with epidemiologic statistics, maps, and graphs for public health professionals who may lack an information technology background.  

The collection of software tools comprising Epi Info™ Desktop equips public health professionals with a wide range of capabilities. These include the ability to: 

- **Conduct Epidemiologic Analysis:** Transform data and perform many types of statistical analyses. Create 2x2 tables and matched-pair case-control studies. Use the new Visual Dashboard feature for regression analysis. Create informative charts using robust chart building capabilities. 

- **Create Forms and Enter Data:** Quickly create questionnaires and data entry forms. Epi Info Desktop will automatically create a database on the basis of a questionnaire designed in the Form Designer module or from an existing data dictionary. Users can enter new data, modify existing data, or search for records. 

- **Generate Maps:** Construct display-quality geographic maps showing data collected using Epi Info Desktop, or display data stored in a variety of other file formats and database systems. More readily identify clusters and trends. Incorporate additional layers to show how data points are related. 

- **Design Custom Solutions:** Leverage Epi Info Desktop’s application programming interface to create custom public health informatics solutions. 

- **Seamless Integration:** Forms and data can easily be shared between Epi Info Desktop and web/cloud products: Epi Info Web Survey, Epi Info Web Analysis and Visualization, and Epi Info Cloud Data Capture as well as with Android and iOS mobile applications. 

Epi Info™ covers the four major functions needed to mitigate a disease outbreak in real time. First, clinical and historical information must be collected from individuals in the affected area as accurately and quickly as possible. This requires an interview questionnaire to systematically collect the data while ensuring the highest possible quality; the Form Designer module supports this function. The Form Designer allows the user to drag and drop different data collection widgets—such as selection menus, check boxes, and text-entry fields—onto a canvas and associate the data collected with variables stored in a database. A system of "check codes" allows the Form Designer to perform logical or mathematical tests to validate the data and disable fields rendered inapplicable by previously entered data. The forms are flexible; new questions can be added during data collection, allowing epidemiologists to pursue new leads in the dynamic environment of a public health emergency. The Enter Data module supports data entry by using the questionnaires developed in Form Designer to prompt the subject and interviewer for specific data. The systematic collection of data makes it possible for the epidemiologist to analyze those data immediately, in contrast to the unstructured interview in which notes need to be collected and interpreted after the fact. 
 

There are two analytical modules in Epi Info™, Classic Analysis and the Visual Dashboard. These offer similar tools but differ in how they are configured and how results are presented. Visual Dashboard is the newest analysis module and has the most up-to-date and user-friendly interface. It allows the user to select standard statistical tests and specialized epidemiological tools from a menu and configure them using a graphical interface. Once the input data are defined, the tool's output, typically in the form of a graph or chart, is dropped onto a canvas. This process can be repeated with as many analyses as needed, turning the canvas into an analytical "dashboard" that is updated every time new data are entered into the system. 

The Map module complements the data collection and analytical modules by allowing the user to plot location data on geographic information system (GIS) base maps or shape files. The locations of individuals can be colored or filtered based on other data such as clinical presentation or risk factors.  Maps can be zoomed in and out and overlaid with demographic data and other reference content. The ability to rapidly create views on the distribution of cases in relation to other factors allows an intuitive exploration of data that can then be used to propose testable hypotheses, shaving weeks or months off the hunt for the source of the outbreak.  This savings of time and effort can not only reduce the financial cost of mitigation efforts, but it can also reduce morbidity and mortality. 
