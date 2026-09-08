function interactive_prop_tool_all()
    % INTERACTIVE_PROP_TOOL_ALL Creates a UI to compare ALL propeller efficiencies.
    % Ensure "9 inch prop data.txt" and "12 inch prop data.txt" are in the 
    % current MATLAB working directory before running.
    
    % 1. Parse data files
    data_9 = parse_prop_file('9 inch prop data.txt');
    data_12 = parse_prop_file('12 inch prop data.txt');
    all_data = [data_9, data_12];
    
    if isempty(all_data)
        uialert(uifigure, 'No valid data found. Ensure the data files are in the same folder.', 'Error');
        return;
    end
    
    % Group props
    props_9 = unique({data_9.Propeller});
    props_12 = unique({data_12.Propeller});
    all_props = [props_9, props_12];
    
    % 2. Create UI Figure
    fig = uifigure('Name', 'All Propellers Efficiency Simulator', 'Position', [50 50 1150 650]);
    
    % Tree for checkboxes (Left panel)
    t = uitree(fig, 'checkbox', 'Position', [20 20 220 610]);
    
    node_all = uitreenode(t, 'Text', 'All Propellers');
    node_9 = uitreenode(node_all, 'Text', '9-inch Propellers');
    node_12 = uitreenode(node_all, 'Text', '12-inch Propellers');
    
    node_map = containers.Map();
    
    for i = 1:length(props_9)
        n = uitreenode(node_9, 'Text', props_9{i});
        node_map(props_9{i}) = n;
    end
    for i = 1:length(props_12)
        n = uitreenode(node_12, 'Text', props_12{i});
        node_map(props_12{i}) = n;
    end
    
    expand(t);
    
    % Pre-select the top 3 to prevent a blank startup screen
    default_props = {'9x4.1SF', '9x4.6SF', '9x4.7SF', '12x4.7SF', '12x5.8SF', '12x4.5MR'};
    nodes_to_check = [];
    for i = 1:length(default_props)
        if isKey(node_map, default_props{i})
            nodes_to_check = [nodes_to_check, node_map(default_props{i})];
        end
    end
    t.CheckedNodes = nodes_to_check;
    
    % UI Axes
    ax = uiaxes(fig, 'Position', [260, 150, 600, 480]);
    title(ax, 'Propeller Efficiency vs. Thrust (All Models)');
    xlabel(ax, 'Static Thrust (Lbf)');
    ylabel(ax, 'Efficiency (g/W)');
    grid(ax, 'on');
    hold(ax, 'on');
    
    % Target Line
    target_thrust = 3.75;
    t_line = xline(ax, target_thrust, 'r:', 'LineWidth', 2, 'DisplayName', 'Target Thrust');
    
    prop_lines = containers.Map();
    prop_data_map = containers.Map();
    
    colors = lines(length(all_props));
    for i = 1:length(all_props)
        prop = all_props{i};
        
        idx = strcmp({all_data.Propeller}, prop);
        subset = all_data(idx);
        if isempty(subset); continue; end
        
        thrusts = [subset.Thrust_lbf];
        effs = [subset.Efficiency_g_W];
        
        [thrusts, sort_idx] = sort(thrusts);
        effs = effs(sort_idx);
        
        valid_idx = thrusts <= 10;
        thrusts = thrusts(valid_idx);
        effs = effs(valid_idx);
        
        prop_data_map(prop) = struct('Thrust', thrusts, 'Efficiency', effs);
        
        lineStyle = '-';
        if startsWith(prop, '12')
            lineStyle = '--';
        end
        
        pl = plot(ax, thrusts, effs, 'LineStyle', lineStyle, ...
            'Color', colors(i,:), 'DisplayName', prop, 'LineWidth', 1.5, 'Visible', 'off');
        prop_lines(prop) = pl;
    end
    
    xlim(ax, [1 9]);
    ylim(ax, [3 10]);
    
    % Slider
    uilabel(fig, 'Position', [280, 100, 150, 20], 'Text', 'Target Thrust (Lbf):', 'FontWeight', 'bold');
    sld = uislider(fig, 'Position', [280, 80, 560, 3], 'Limits', [1 9], 'Value', target_thrust);
    
    % Readout Text Area (Right panel)
    readout = uitextarea(fig, 'Position', [880, 20, 250, 610], 'Editable', 'off', 'FontSize', 13);
    
    % Callbacks
    t.CheckedNodesChangedFcn = @(src, event) update_plot_and_readout();
    sld.ValueChangedFcn = @(src, event) update_plot_and_readout();
    
    % Initial update
    update_plot_and_readout();
    
    % --- Nested Callback Function ---
    function update_plot_and_readout()
        thrust = sld.Value;
        t_line.Value = thrust;
        
        % Get checked nodes
        checked = t.CheckedNodes;
        checked_props = {};
        for k = 1:length(checked)
            % Ignore the parent category nodes
            if ~strcmp(checked(k).Text, 'All Propellers') && ...
               ~strcmp(checked(k).Text, '9-inch Propellers') && ...
               ~strcmp(checked(k).Text, '12-inch Propellers')
                checked_props{end+1} = checked(k).Text;
            end
        end
        
        text_out = {sprintf('Efficiencies at %.2f Lbf:\n', thrust)};
        
        % Iterate and sort text output by highest efficiency
        eff_results = [];
        prop_names = {};
        
        for k = 1:length(all_props)
            p = all_props{k};
            if isKey(prop_lines, p)
                pl = prop_lines(p);
                if ismember(p, checked_props)
                    pl.Visible = 'on';
                    
                    d = prop_data_map(p);
                    if thrust >= min(d.Thrust) && thrust <= max(d.Thrust)
                        eff = interp1(d.Thrust, d.Efficiency, thrust, 'linear');
                        eff_results(end+1) = eff;
                        prop_names{end+1} = p;
                    else
                        eff_results(end+1) = -1; % Out of range flag
                        prop_names{end+1} = p;
                    end
                else
                    pl.Visible = 'off';
                end
            end
        end
        
        % Sort readouts so highest efficiency is at the top
        [eff_results, sort_id] = sort(eff_results, 'descend');
        prop_names = prop_names(sort_id);
        
        for k = 1:length(eff_results)
            if eff_results(k) == -1
                text_out{end+1} = sprintf('%s: Out of range', prop_names{k});
            else
                text_out{end+1} = sprintf('%s: %.2f g/W', prop_names{k}, eff_results(k));
            end
        end
        
        readout.Value = text_out;
    end
end

% --- Helper Parsing Function ---
function data = parse_prop_file(filepath)
    data = struct('Propeller', {}, 'Thrust_lbf', {}, 'Efficiency_g_W', {});
    fid = fopen(filepath, 'r');
    if fid == -1
        warning('Cannot open file: %s', filepath);
        return;
    end
    
    current_prop = 'Unknown';
    count = 1;
    
    while ~feof(fid)
        line = fgetl(fid);
        
        % Check for propeller name
        % Matches formatting: "   9x4.1SF                  (9x41SF.dat)"
        tokens = regexp(line, '^\s+([a-zA-Z0-9\.]+)\s+\([a-zA-Z0-9\.]+\.dat\)', 'tokens');
        if ~isempty(tokens)
            current_prop = strtrim(tokens{1}{1});
        end
        
        % Check for data line starting with "0.00" and containing "0.0000"
        if startsWith(strtrim(line), '0.00') && contains(line, '0.0000')
            parts = strsplit(strtrim(line));
            if length(parts) >= 12
                try
                    thrust = str2double(parts{8});
                    eff = str2double(parts{12});
                    
                    data(count).Propeller = current_prop;
                    data(count).Thrust_lbf = thrust;
                    data(count).Efficiency_g_W = eff;
                    count = count + 1;
                catch
                    % Ignore parsing errors for malformed lines
                end
            end
        end
    end
    fclose(fid);
end