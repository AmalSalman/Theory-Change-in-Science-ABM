/**
* Name: TheoryChangeBEN
* Author: Amal Salman
*/


model TheoryChangeBEN

global{
	
	// Vocabulary of the model: defining beliefs and desires
	// Beliefs:
	predicate smokeExists <- new_predicate("smokeExists");
	predicate smokeSerious <- new_predicate("smokeSerious");
	predicate mustInvestigate <- new_predicate("mustInvestigate");
	// Desires:
	predicate to_exit <- new_predicate("to_exit");
	predicate to_stay <- new_predicate("to_stay");
	predicate to_investigate <- new_predicate("to_investigate");
	predicate to_influence_others <- new_predicate("to_influence_others");
	predicate to_publish <- new_predicate("to_publish");
	
	// *** Parameters ***
	
	// Meta-parameters
	float interaction_level <- 0.5 min: 0.0 max: 1.0 parameter: true; // Level of interaction between agents
	float peer_influence_level <- 0.5 min: 0.0 max: 1.0 parameter: true; // Influence level of peers
	float anomaly_difficulty_level <- 0.5 min: 0.0 max: 1.0 parameter: true; // Difficulty level of the anomaly
	bool is_batch <- false parameter: true; // Used to remove stopping condition in batch simulation
	bool in_parallel <- true parameter: true; // Run simulations in parallel
	
	// General parameters
	int nb_scientists <- 500 min: 250 max: 1500 parameter: true; // Number of scientists
	bool model_version_2 <- false parameter: true; // Indicates if using version 2 of the model
	bool defined_anomaly <- false parameter: true; // Indicates if the anomaly is predefined
	bool defined_true_anomaly <- false parameter: true; // Indicates if the true anomaly is predefined
	int exit_location <- 8 parameter: true; // Identifies which wall section the exit is located (12 total)
	
	// Estimated parameters
	float acceptance_rate <- 0.32; // Probability of publication acceptance
	int cycles_per_year <- 2; // Number of cycles per year
	int max_cycles <- 50*cycles_per_year; // Maximum number of cycles
	
	// Excluded parameters
	// Dimension of the grid agent
	int nb_cols <- 100;
	int nb_rows <- 105;
	
	int fire_center_x <- 8;
	int fire_center_y <- 8;
	
	// Not used
	float par_openness_mean <- 0.710; 
	float par_conscientiousness_mean <- 0.568; 
	float par_extroversion_mean <- 0.668; 
	float par_agreeableness_mean <- 0.620; 
	float par_neurotism_mean <- 0.593; 
	
	float par_openness_std <- 0.178;
	float par_conscientiousness_std <- 0.18;
	float par_extroversion_std <- 0.195;
	float par_agreeableness_std <- 0.190;
	float par_neurotism_std <- 0.183;
	
	// Derived from interaction_level:
	// Environment
	float par_smoke_spread_rate <- (1-interaction_level)*0.5/100; 	
	
	// Agent spatial properties
	float par_vision_amplitude <- interaction_level*(180-18) + 18; // Field of vision angle
	float par_agent_size <- interaction_level*(4-1) + 1; // Size of the agent
	float par_max_perceived_distance <- interaction_level*(32-3.2) + 3.2; // Maximum perceived distance
	float par_average_speed <- interaction_level*10; // Average speed of agents
	float par_wandering_distance <- interaction_level*60; // Wandering distance
	
	// Derived from anomaly_difficulty_level:
	float par_max_impact <- (1 - anomaly_difficulty_level)*(0.1-0.01) + 0.01; // Maximum impact of publications
	float par_partial_impact <- 1 - anomaly_difficulty_level; // Partial impact of publications
	float par_cycles_for_full_understanding <- anomaly_difficulty_level*(10*cycles_per_year - cycles_per_year) + cycles_per_year; // Time for full understanding of anomaly
	
	// File path for grid matrix based on exit location
	string file_name <- "../includes/grid_matrix_" + exit_location + ".csv";
	
	// Lists for different types of cells
	list<cell> free_cells;
	list<cell> walls;
	list<cell> exit_cells;
	list<cell> exit_area_cells;
	list<cell> expert_level_5_cells;
	
	bool true_anomaly; // Indicates if the anomaly is true
	
	init{
		// Set parallel processing preferences
		if in_parallel{
			gama.pref_parallel_grids <- false;
			gama.pref_parallel_simulations <- true;
			gama.pref_parallel_species <- true;
		}
		else{
			gama.pref_parallel_grids <- false;
			gama.pref_parallel_simulations <- false;
			gama.pref_parallel_species <- false;
		}
				
		step <- 0.25 #year; // Simulation step size
		
		// Load grid matrix from CSV file
		file grid_csv <- csv_file(file_name);
		matrix grid_matrix <- matrix(grid_csv);
		
		// Assign cell properties based on grid matrix values
		ask cell {
            grid_value <- float(grid_matrix[grid_x,grid_y]);
		}
		
		ask cell{
            if(grid_value = 1){
            	is_wall <- true;
            	color <- #black;
            }
            else if(grid_value = 2){
            	is_exit <- true;
            	color <- #blue;
            }
            else if(grid_value = 3){
            	is_in_exit_area <- true;
            	color <- rgb(255,233,214);
            }
            else if(grid_value = 11){
            	is_expert_level_1 <- true;
//            	color <- #brown;
            }
             else if(grid_value = 22){
            	is_expert_level_2 <- true;
//            	color <- #red;
            }
             else if(grid_value = 33){
            	is_expert_level_3 <- true;
//            	color <- #pink;
            }
             else if(grid_value = 44){
            	is_expert_level_4 <- true;
//            	color <- #yellow;
            }
             else if(grid_value = 55){
            	is_expert_level_5 <- true;
//            	color <- #green;
            }
        }
        
        // Determine if the anomaly is true or false based on model version and difficulty
        if model_version_2{
        	if defined_anomaly{
        		true_anomaly <- defined_true_anomaly;
        	}
        	else{
	        	if flip (anomaly_difficulty_level){ // The more "difficult" the anomaly, the more likely it'll cause a paradigm shift
	        		true_anomaly <- true;
	        	}
	        	else{
	        		true_anomaly <- false;
	        	}
        	}
        }
        else{
        	true_anomaly <- true;
        }
        
        // Initialize cell lists
        free_cells <- cell where (not each.is_wall and not each.is_in_exit_area);
        walls <- cell where each.is_wall;
        exit_cells <- cell where each.is_exit;
        exit_area_cells <- cell where each.is_in_exit_area;
        expert_level_5_cells <- cell where each.is_expert_level_5;
        
        // Create fire and initial proposer scientist
        create fire number:1;
		create scientist number: 1 with: [is_proposer::true, location::one_of(expert_level_5_cells).location];
		create scientist number: nb_scientists;
	}
	
	// **** Tracking/counting agent variables ****
	int nb_investigating <- 0;
	int nb_exited_total <- 0;
	float saved_smoke_level <- 0.0;
	float saved_theory_level <- 0.0;
	
	float theory_level <- 0.0 max: 100.0 min: 0.0;
	float new_publications_smoke <- 0.0;
	float new_publications_theory <- 0.0;
	
	int first_investigator_at_cycle <- -1; // -1 signifies no investigators 
	int first_exiter_at_cycle <- -1;
	int max_exited_at_cycle;
	//   **************

	// Stop simulation when maximum cycles reached or majority have exited
	reflex stop when: ((cycle > max_cycles) or (nb_exited_total >= nb_scientists/2)) and !is_batch{ 
		do pause;
	}
	
	// Track agents and reset counts every cycle
	reflex tracking_agents_and_saving{ 
		if nb_exited_total > 0 and first_exiter_at_cycle = -1{
			first_exiter_at_cycle <- cycle;
		}
		
		if nb_investigating > 0 and first_investigator_at_cycle = -1{
			first_investigator_at_cycle <- cycle;
		}
		
		// Reset counts
		nb_investigating <- 0;
		nb_exited_total <- 0;
	}
}

// Grid species to discretize space
grid cell width: nb_cols height: nb_rows neighbors: 8 {
	bool is_wall <- false;
	bool is_exit <- false;
	bool is_in_exit_area <- false;
	bool is_expert_level_1 <- false;
	bool is_expert_level_2 <- false;
	bool is_expert_level_3 <- false;
	bool is_expert_level_4 <- false;
	bool is_expert_level_5 <- false;
	float smoke_level <- 0.0 max: 1.0 min:0.0;
	rgb color <- #white;
	
	// Update cell color based on smoke level
	reflex updateColor when: not is_batch{
		if(grid_value != 1 and grid_value != 2){
			if (smoke_level > 0.0 and smoke_level<=0.10){
				color <- rgb(235,235,235);
			}
			else if(smoke_level>0.10 and smoke_level<=0.20){
				color <-rgb(220,220,220);
			}
			else if(smoke_level>0.20 and smoke_level<=0.30){
				color <-rgb(200,200,200);
			}
			else if(smoke_level>0.30 and smoke_level<=0.40){
				color <-rgb(170,170,170);
			}
			else if(smoke_level>0.40 and smoke_level<=0.50){
				color <-rgb(140,140,140);
			}
			else if(smoke_level>0.50 and smoke_level<=0.60){
				color <-rgb(100,100,100);
			}
			else if(smoke_level>0.60 and smoke_level<=0.70){
				color <-rgb(70,70,70);
			}
			else if(smoke_level>0.70 and smoke_level<=0.80){
				color <-rgb(50,50,50);
			}
			else if(smoke_level>0.80 and smoke_level<=0.90){
				color <-rgb(45,45,45);
			}
			else if(smoke_level>0.90 and smoke_level<1.0){
				color <-rgb(40,40,40);
			}
			else if(smoke_level=1.0){
				color <-rgb(30,30,30);
			}
		}
	}
	
	// Update smoke level at the fire center
	reflex update_smoke_level when: grid_x=fire_center_x and grid_y=fire_center_y{
		smoke_level <- smoke_level + new_publications_smoke;
		theory_level <- max(0.0, min(1.0, theory_level + new_publications_theory));
		new_publications_smoke <- 0.0;
		new_publications_theory <- 0.0;
		
		saved_smoke_level <- smoke_level; // Track/save levels at the central cell
		saved_theory_level <- theory_level;
	}
	
	// Propagate smoke to neighboring cells
	reflex propagationSmoke when: smoke_level > 0 {
		ask neighbors{
			if(grid_value != 1 and grid_value != 2 ){ 
				if(smoke_level<=1.0 and smoke_level<myself.smoke_level){
					smoke_level<-myself.smoke_level;
					if smoke_level <= 0.95 { // When smoke spreads to another cell it decreases in current cell, except after 95%
						myself.smoke_level <- myself.smoke_level - par_smoke_spread_rate;
					}
				}
			}
		}
	}
}

// Species representing the fire
species fire {	
	rgb f_color <- #orange;
	int fire_size <- 4;
	
	init {
		location <- cell[fire_center_x, fire_center_y].location;
	}
	
	aspect default {
		draw sphere(fire_size) color: f_color;
	}	
}

// Species representing the scientist
species scientist skills: [moving] control: simple_bdi {
	point target;
	rgb agent_color;
	float agent_size;
	float perceived_distance;
	geometry perceived_area;
	path myPath;
	int expert_level;
	float threshold_seriousness;
	float threshold_investigating;
	float threshold_theory;
	int nb_cycles_investigating;
	float perceived_smoke_level;
	float perceived_theory_level;
	float disengagement_level min: 0.0 max: 1.0;
	
	float influence_score;
	float max_perceived_agents;
	
	int nb_perceived_smokeSerious;
	int nb_perceived_not_smokeSerious;
	cell exit_area_cell;
	cell target_cell;
	bool in_exit_area;
	bool reached_exit;
	bool is_proposer <- false;
	int nb_publications;
	int nb_published_correctly;
	
	// Action to make the agent walk
	action walk {
		float actual_speed <- speed;
		if (myPath != nil) {
			do follow path: myPath speed: actual_speed;
		} else {
			do goto(target);
		}
	}
	
	// Action to update the path to a new target
	action update_path(point new_target) {
		if (target = nil) or (target != new_target) or (myPath = nil) or (myPath.target != new_target) {
			target <- new_target;
			myPath <- free_cells path_between (self.location, target);
		}
	}
	
	// Action to update the perceived area based on vision amplitude
	action update_perceived_area {
		par_vision_amplitude <- 90.0;
		if (par_vision_amplitude < 180.0) {  // Otherwise the vision cone becomes a circle
			geometry vision_cone <- cone(int(heading - par_vision_amplitude), int(heading + par_vision_amplitude)); // Heading is the absolute heading of the agent in degrees
			perceived_area <- vision_cone intersection circle(perceived_distance); 
		} else {
			perceived_area <- circle(perceived_distance);
		}
	}
	
	// Action to walk to the exit
	action walk_to_exit {
		if (target != (exit_cells closest_to self).location) {
			do update_path((exit_cells closest_to self).location);
		}
		do walk;
		
		if (self distance_to target < (speed * step)) {
			reached_exit <- true;
		}
	}
	
	// Action to publish correctly if the anomaly is true
	action publish_correctly {
		if (true_anomaly) {
			new_publications_smoke <- new_publications_smoke + par_max_impact * ((expert_level - 1) / 4);
			new_publications_theory <- new_publications_theory + par_partial_impact * par_max_impact * ((expert_level - 1) / 4);
		} else {
			new_publications_smoke <- new_publications_smoke - par_max_impact * ((expert_level - 1) / 4);
			new_publications_theory <- new_publications_theory - par_partial_impact * par_max_impact * ((expert_level - 1) / 4);
		}
	}
	
	// Action to publish incorrectly if the anomaly is false
	action publish_incorrectly {
		if (true_anomaly) {
			new_publications_smoke <- new_publications_smoke - par_max_impact * ((expert_level - 1) / 4);
			new_publications_theory <- new_publications_theory - par_partial_impact * par_max_impact * ((expert_level - 1) / 4);
		} else {
			new_publications_smoke <- new_publications_smoke + par_max_impact * ((expert_level - 1) / 4);
			new_publications_theory <- new_publications_theory + par_partial_impact * par_max_impact * ((expert_level - 1) / 4);
		}
	}
	
	aspect default {		
		draw triangle(par_agent_size) rotate: 90 + heading color: agent_color border: false;
	}
	
	init {
		// Assign location and update perception
		if not is_proposer {
			location <- one_of(free_cells).location; // Random initial position
		}
		
		// Assign expert level based on location
		if cell(location).is_expert_level_1 {
			expert_level <- 1;
		} else if cell(location).is_expert_level_2 {
			expert_level <- 2;
		} else if cell(location).is_expert_level_3 {
			expert_level <- 3;
		} else if cell(location).is_expert_level_4 {
			expert_level <- 4;
		} else if cell(location).is_expert_level_5 {
			expert_level <- 5;
		}
		
		// Update perception based on location and expert_level (initial random position)
		perceived_distance <- par_max_perceived_distance * ((expert_level - 1) / 4);
		do update_perceived_area; 
		
		speed <- par_average_speed; // Same for everyone
		
		exit_area_cell <- one_of(exit_area_cells);
		in_exit_area <- false;
		reached_exit <- false;
		
		// max_perceived_agents in one cycle
		max_perceived_agents <- nb_scientists / 6 * perceived_distance / par_max_perceived_distance;
		
		// Assign personality traits using truncated Gaussian distribution
		use_personality <- true;
		openness <- min(1, max(0, truncated_gauss([par_openness_mean, par_openness_std]) with_precision(3))); // Ensure values are within [0, 1], otherwise possible error: The sqrt operator cannot accept negative inputs
		conscientiousness <- min(1, max(0, truncated_gauss([par_conscientiousness_mean, par_conscientiousness_std]) with_precision(3))); 
		extroversion <- min(1, max(0, truncated_gauss([par_extroversion_mean, par_extroversion_std]) with_precision(3)));
		agreeableness <- min(1, max(0, truncated_gauss([par_agreeableness_mean, par_agreeableness_std]) with_precision(3)));
		neurotism <- min(1, max(0, truncated_gauss([par_neurotism_mean, par_neurotism_std]) with_precision(3)));
		
		// Initial beliefs and desires for the proposer
		if is_proposer {
			do add_belief(mustInvestigate);
			do add_desire(to_investigate);
		} else {
			do add_desire(to_stay); // Initial desire state (staying/working)
			
			// Initial desire to intentionally influence others depending on personality
			if flip(extroversion) {
				do add_desire(to_influence_others);
			}
		}
		
		// Thresholds (not dynamic, but everyone can eventually reach them)
		threshold_seriousness <- conscientiousness;
		threshold_investigating <- (1 - openness) * threshold_seriousness; // Partial threshold_seriousness
		threshold_theory <- (1 - openness);
		
		// Visual representation
		agent_color <- rgb(167, 36, 36);
		
		// Initialize count variables
		nb_perceived_smokeSerious <- 0;
		nb_perceived_not_smokeSerious <- 0;
		nb_publications <- 0;
		nb_published_correctly <- 0;
	 	 
		disengagement_level <- 0.0; // No disengagement at cycle 0 but will immediately increase because of surrounding agents
		influence_score <- 0.0;
	}

	// Perception of the environment
	perceive target: self parallel: false {
		do update_perceived_area;
	}
	
	// Perception of smoke level and theory level in cells
	perceive target: cell in: perceived_area parallel: false {
		if myself.perceived_smoke_level < 1.0 {
			myself.perceived_smoke_level <- (1 - myself.disengagement_level) * smoke_level;
		}
		if myself.perceived_theory_level < 1.0 {
			myself.perceived_theory_level <- (1 - myself.disengagement_level) * theory_level;
		}
		
		if not myself.has_belief(smokeExists) {
			if (myself.perceived_smoke_level > 0.0) {
				focus id:"smokeExists";
			}
		} else {
			if myself.perceived_smoke_level >= myself.threshold_investigating {
				focus id:"mustInvestigate";
			}
			if myself.perceived_smoke_level >= myself.threshold_seriousness {
				focus id:"smokeSerious";
				ask myself {
					do remove_belief(mustInvestigate);
				}
			}
			if myself.has_belief(mustInvestigate) and myself.perceived_smoke_level < myself.threshold_investigating and not myself.is_proposer {
				ask myself {
					do remove_belief(mustInvestigate);
				}
			}
		}
	}
	
	// Update beliefs and desires based on perceptions
	rule belief: mustInvestigate remove_desire: to_stay remove_intention: to_stay new_desire: to_investigate;
	rule desire: to_investigate when: ((perceived_smoke_level < threshold_investigating) and not is_proposer) remove_desire: to_investigate remove_intention: to_investigate new_desire: to_stay;
	rule belief: smokeSerious when: perceived_theory_level >= threshold_theory remove_desire: to_investigate remove_intention: to_investigate new_desire: to_exit; // remove_belief doesn't work
	rule belief: smokeSerious when: not (perceived_theory_level >= threshold_theory) remove_desire: to_investigate remove_intention: to_investigate new_desire: to_stay; // remove_belief doesn't work
	
	// Perception of other scientists in the perceived area
	perceive target: scientist in: perceived_area {			
		if (has_belief(smokeSerious) or has_belief(mustInvestigate)) and max_perceived_agents != 0 {
			if has_belief(smokeSerious) {
				nb_perceived_smokeSerious <- nb_perceived_smokeSerious + 1;
			}
			influence_score <- influence_score + (peer_influence_level / max_perceived_agents);
		} else if max_perceived_agents != 0 { // They don't believe smokeSerious
			influence_score <- influence_score - (peer_influence_level / max_perceived_agents);
			if not has_belief(smokeSerious) {
				nb_perceived_not_smokeSerious <- nb_perceived_not_smokeSerious + 1;
			}
		}
		
		if expert_level > myself.expert_level {
			influence_score <- influence_score + (influence_score * peer_influence_level);
		}
		
		if has_desire(to_influence_others) {
			influence_score <- influence_score + (influence_score * peer_influence_level);
		}
	}	
	
	// Update disengagement level based on influence score and conscientiousness
	reflex update_disengagement_level {		
		disengagement_level <- min(1, max(0, disengagement_level + (influence_score * (1 - conscientiousness))));
	}
	
	// Define the Staying plan
	plan Staying intention: to_stay finished_when: ((has_desire(to_influence_others) and has_belief(smokeSerious) and perceived_theory_level < threshold_theory) or (has_belief(smokeSerious) and perceived_theory_level >= threshold_theory)) {
		agent_color <- rgb(167, 36, 36);
		if par_wandering_distance != 0 { // When par_wandering_distance = 0 agents don't move
			if (target = nil) {
				target_cell <- one_of(free_cells where (each distance_to self < par_wandering_distance));
				if target_cell != nil { // Avoid error: unable to compute location because agent is nil
					target <- target_cell.location;
					myPath <- free_cells path_between(location, target);
					do walk;
				} // Else will stay in place until next cycle
			}
			
			if (self distance_to target < (speed * step)) {
				target <- nil;
			}
		}
	}
	
	// Define the AdvocatingToStay plan
	plan AdvocatingToStay intention: to_stay when: (has_desire(to_influence_others) and has_belief(smokeSerious) and perceived_theory_level < threshold_theory) finished_when: perceived_theory_level >= threshold_theory {
		agent_color <-  rgb(252, 54, 54);
		
		if par_wandering_distance != 0 {
			if (target = nil) {
				scientist closest_agent <- scientist closest_to(self);
				if closest_agent.has_desire(to_investigate) {
					// Go to one of cells surrounding them
					target_cell <- one_of(free_cells where (each distance_to (scientist closest_to(self)) <= 2.0));
					if target_cell != nil { // Avoid error: unable to compute location because agent is nil
						target <- target_cell.location;
						myPath <- free_cells path_between(location, target);
						do walk;
					} // Else will stay in place until next cycle
				} else {
					target_cell <- one_of(free_cells where (each distance_to self < par_wandering_distance));
					if target_cell != nil { // Avoid error: unable to compute location because agent is nil
						target <- target_cell.location;
						myPath <- free_cells path_between(location, target);
						do walk;
					} // Else will stay in place until next cycle
				}			
			}
			
			if (self distance_to target < (speed * step)) {
				target <- nil;
			}
		}	
	}
	
	// Define the Investigating plan
	plan Investigating intention: to_investigate when: obedience < ((expert_level - 1) / 4) {
		nb_cycles_investigating <- nb_cycles_investigating + 1;
		nb_investigating <- nb_investigating + 1;
		agent_color <- rgb(141, 90, 78);
		
		if par_wandering_distance != 0 {
			if (target = nil) {
				target_cell <- one_of(free_cells where (each distance_to self < par_wandering_distance));
				if target_cell != nil { // Avoid error: unable to compute location because agent is nil
					target <- target_cell.location;
					myPath <- free_cells path_between(location, target);
					do walk;	
				} // Else will stay in place until next cycle		
			}
			
			if (self distance_to target < (speed * step)) {
				target <- nil;
			}		
		}
		
		if is_proposer and nb_publications = 0 {
			disengagement_level <- 0.0;
			nb_publications <- nb_publications + 1;
			do publish_correctly;
		}
		
		if has_desire(to_publish) {
			if flip (acceptance_rate) { // Accepted by journal
				disengagement_level <- 0.0;
				nb_publications <- nb_publications + 1;
				do remove_desire(to_publish);
				if model_version_2 {
					if nb_published_correctly = 0 {
						if flip(nb_cycles_investigating / par_cycles_for_full_understanding * ((expert_level - 1) / 4)) {
							do publish_correctly;
							nb_published_correctly <- nb_published_correctly + 1;
						} else {
							do publish_incorrectly;
						}
					} else {
						if nb_publications > 0 {
							if flip(nb_published_correctly / nb_publications * nb_cycles_investigating / par_cycles_for_full_understanding * ((expert_level - 1) / 4)) {
								do publish_correctly;
								nb_published_correctly <- nb_published_correctly + 1;
							} else {
								do publish_incorrectly;
							}
						} else {
							if flip(nb_cycles_investigating / par_cycles_for_full_understanding * ((expert_level - 1) / 4)) {
								do publish_correctly;
								nb_published_correctly <- nb_published_correctly + 1;
							} else {
								do publish_incorrectly;
							}
						}
					}
				} else {
					do publish_correctly;
				}
			}
		} else {
			if nb_cycles_investigating = par_cycles_for_full_understanding {
				do add_desire(to_publish);
			} else {
				if flip ((1 - conscientiousness) * (nb_cycles_investigating / par_cycles_for_full_understanding)) {
					do add_desire(to_publish);
				}
			}
		}
	}
	
	// Define the FollowOthers norm
	norm FollowOthers intention: to_investigate threshold: ((expert_level - 1) / 4) finished_when: has_belief(smokeSerious) { // Activated when agent's obedience > threshold
		if nb_perceived_smokeSerious > nb_perceived_not_smokeSerious {
			do add_belief(smokeSerious);
			do remove_belief(mustInvestigate);
		}
		
		agent_color <- rgb(167, 36, 36);
		
		if par_wandering_distance != 0 {
			if (target = nil) {
				target_cell <- one_of(free_cells where (each distance_to self < par_wandering_distance));
				if target_cell != nil { // Avoid error: unable to compute location because agent is nil
					target <- target_cell.location;
					myPath <- free_cells path_between(location, target);
					do walk;
				} // Else will stay in place until next cycle
			}
			
			if (self distance_to target < (speed * step)) {
				target <- nil;
			}
		}
	}
	
	// Define the Exiting plan
	plan Exiting intention: to_exit when: not has_desire(to_influence_others) {
		agent_color <- rgb(15, 162, 69);

		nb_exited_total <- nb_exited_total + 1; // This counts agents on way to exit, exited, or advocating to exit
				
		if not reached_exit {
			do walk_to_exit;
		} else {
			if not in_exit_area {
				location <- exit_area_cell.location;				
				in_exit_area <- true;
			}
		}
		
		if has_desire(to_publish) {
			disengagement_level <- 0.0;
			if flip (acceptance_rate) { // Accepted by journal
				nb_publications <- nb_publications + 1;
				do remove_desire(to_publish);
				
				new_publications_smoke <- new_publications_smoke + par_partial_impact * par_max_impact;
				new_publications_theory <- new_publications_theory + par_max_impact;
			}
		} else {
			if flip (1 - conscientiousness) { // Want to publish
				do add_desire(to_publish);
			}
		}
	}
	
	// Define the AdvocatingToExit plan
	plan AdvocatingToExit intention: to_exit when: has_desire(to_influence_others) {
		agent_color <-  rgb(44, 235, 114);

		nb_exited_total <- nb_exited_total + 1; // This counts agents on way to exit, exited, or advocating to exit
		
		if par_wandering_distance != 0 {
			if (target = nil) {
				scientist closest_agent <- scientist closest_to(self);
				if closest_agent.has_desire(to_investigate) {
					// Go to one of cells surrounding them
					target_cell <- one_of(free_cells where (each distance_to (scientist closest_to(self)) <= 2.0));
					if target_cell != nil { // Avoid error: unable to compute location because agent is nil
						target <- target_cell.location;
						myPath <- free_cells path_between(location, target);
						do walk;
					} // Else will stay in place until next cycle	
				} else {
					target_cell <- one_of(free_cells where (each distance_to self < par_wandering_distance));
					if target_cell != nil { // Avoid error: unable to compute location because agent is nil
						target <- target_cell.location;
						myPath <- free_cells path_between(location, target);
						do walk;
					} // Else will stay in place until next cycle	
				}			
			}
			
			if (self distance_to target < (speed * step)) {
				target <- nil;
			}
		}
		
		if has_desire(to_publish) {
			disengagement_level <- 0.0;
			if flip (acceptance_rate) { // Accepted by journal
				nb_publications <- nb_publications + 1;
				do remove_desire(to_publish);
				
				new_publications_smoke <- new_publications_smoke + par_partial_impact * par_max_impact;
				new_publications_theory <- new_publications_theory + par_max_impact;
			}
		} else {
			if flip (1 - conscientiousness) { // Want to publish
				do add_desire(to_publish);
			}
		}
	}
	
	// Reset influence scores and counts for each agent every cycle
	reflex count_agents {
		// Resetting
		influence_score <- 0.0;
		nb_perceived_smokeSerious <- 0;
		nb_perceived_not_smokeSerious <- 0;
	}
}

// Experiment setup for model visualization
experiment model_visualization type: gui {	
	init {
		is_batch <- false;
		
		interaction_level <- 0.9; 
		peer_influence_level <- 0.5; 
		anomaly_difficulty_level <- 0.7; 
		nb_scientists <- 250;
	}
	
	output {
		display my_display {
			grid cell;
			species scientist;
			species fire;
		}
		
		display map {
			overlay position: { 0, 0 } size: { 230 #px, 260 #px } background: #black transparency: 0.5 border: #black rounded: true {
				float y <- 30 #px;
				draw triangle(20 #px) at: { 20 #px, 30 #px } color: rgb(252, 54, 54);
				draw "Advocating To Stay" at: { 40 #px, 30 #px + 4 #px } color: #white font: font("SansSerif", 18, #bold);
				draw triangle(20 #px) at: { 20 #px, 55 #px } color: rgb(167, 36, 36);
				draw "Staying" at: { 40 #px, 55 #px + 4 #px } color: #white font: font("SansSerif", 18, #bold);
				draw triangle(20 #px) at: { 20 #px, 80 #px } color: rgb(141, 90, 78);
				draw "Investigating" at: { 40 #px, 80 #px + 4 #px } color: #white font: font("SansSerif", 18, #bold);
				draw triangle(20 #px) at: { 20 #px, 105 #px } color: rgb(15, 162, 69);
				draw "Exiting" at: { 40 #px, 105 #px + 4 #px } color: #white font: font("SansSerif", 18, #bold);
				draw triangle(20 #px) at: { 20 #px, 130 #px } color: rgb(44, 235, 114);
				draw "Advocating To Exit" at: { 40 #px, 130 #px + 4 #px } color: #white font: font("SansSerif", 18, #bold);
			}
		}
		
		display chart_1 {
			chart "Number of scientists investigating/exiting" {
				data "exited" value: nb_exited_total color: rgb(15, 162, 69);
				data "investigating" value: nb_investigating color: rgb(141, 90, 78);
			}
		}
	}
}
