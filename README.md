# Theory-Change-in-Science-ABM

This repository contains associated files for the master's thesis titled "Exploring Cognitive Architectures in the Social Epistemology of Science: An Agent-Based Model" by Amal Salman. This project models the process of theory change in scientific communities using an agent-based model (ABM) implemented in the GAMA platform. The model uses uses the BEN cognitive architecture to simulate decision-making processes of agents (scientists), and focuses on how individual cognitive processes and social interactions influence the replacement of a dominant theory in the face of an anomaly. The model is analogous to a fire evacuation model, where the fire represents an anomaly in the dominant theory, and the smoke spreading from it represents the accumulation of evidence supporting the anomaly. Scientists (agents) in the model can investigate the anomaly, publish findings that increase the "smoke level" (strength of evidence), and ultimately decide whether to exit/evacuate, representing that they abandoned their current theory and adopted a new one.


## Files included:

- The full model code in Theory_Change_BEN/models/Theory_Change_BEN.gaml with supporting files required in Theory_Change_BEN/includes
- Alternatively, a compressed final_model.zip that can be more easily imported in GAMA.
- The complete ODD (Overview, Design concepts, Details) protocol for the model (Full Model Describtion (ODD).pdf).
- A video demonstrating the model's dynamics (Example simulation.mp4) using 250 agents and the parameter settings: interaction_level = 0.9,	peer_influence_level = 0.5, anomaly_difficulty_level = 0.7


## How to Use:

1. Download and install the GAMA platform (version 1.9.3) from the official website: https://gama-platform.org/
2. Copy the Theory_Change_BEN folder or clone this repository into your GAMA_Workspace folder
3. Alternatively, download final_model.zip open GAMA, right-click on User Models, click on Import -> GAMA Project, choose Select archive file and locate the .zip file in your downloads folder.
4. Open the TheoryChangeBEN.gaml model file in GAMA.
5. Run the model by clicking the 'model_visualization' play button in GAMA.
6. Explore the model's behavior by running simulations with different parameter settings, changing them in the parameters pane.
