function plot_badass_interactive()
    filename = 'BadAss_4S_Consolidated_Data.txt';
    if ~isfile(filename)
        uialert(uifigure, sprintf('File "%s" not found in current directory.', filename), 'File Error');
        return;
    end
    
    % 1. Parse data file
    raw_data = parse_consolidated_file(filename);
    if isempty(raw_data)
        uialert(uifigure, 'No valid records found in data file.', 'Empty Data');
        return;
    end
    
    % Global bounds for limits
    all_thrusts = [raw_data.ThrustGrams];
    min_thrust_init = floor(min(all_thrusts));
    max_thrust_init = ceil(max(all_thrusts));
    
    % 2. Setup Main App Window
    fig = uifigure('Name', 'BadAss 4S Propulsion Visualizer', 'Position', [60, 60, 1260, 720]);
    
    % Control Panel
    pnl = uipanel(fig, 'Position', [20, 635, 1220, 65], 'Title', 'Filter & Diameter Controls');
    
    uilabel(pnl, 'Position', [15, 12, 105, 22], 'Text', 'Prop Diameter:', 'FontWeight', 'bold');
    diam_dd = uidropdown(pnl, 'Position', [115, 12, 130, 24], ...
        'Items', {'All Diameters', '9-inch Only', '12-inch Only'}, ...
        'Value', 'All Diameters');
    
    uilabel(pnl, 'Position', [270, 12, 100, 22], 'Text', 'Min Thrust (g):', 'FontWeight', 'bold');
    min_box = uieditfield(pnl, 'numeric', 'Position', [370, 12, 90, 24], ...
        'Value', min_thrust_init, 'Limits', [0, inf]);
    
    uilabel(pnl, 'Position', [480, 12, 100, 22], 'Text', 'Max Thrust (g):', 'FontWeight', 'bold');
    max_box = uieditfield(pnl, 'numeric', 'Position', [580, 12, 90, 24], ...
        'Value', max_thrust_init, 'Limits', [0, inf]);
    
    uilabel(pnl, 'Position', [695, 12, 70, 22], 'Text', 'Sort Table:', 'FontWeight', 'bold');
    sort_dd = uidropdown(pnl, 'Position', [770, 12, 160, 24], ...
        'Items', {'Thrust: High to Low', 'Thrust: Low to High', 'Eff: High to Low'}, ...
        'Value', 'Thrust: High to Low');
    
    reset_btn = uibutton(pnl, 'push', 'Position', [950, 12, 80, 24], 'Text', 'Reset', ...
        'ButtonPushedFcn', @(~,~) reset_filters());
    
    status_lbl = uilabel(pnl, 'Position', [1045, 12, 160, 22], 'Text', '', 'FontColor', [0.2, 0.4, 0.7]);
    
    % Main Plotting Canvas
    ax = uiaxes(fig, 'Position', [20, 30, 780, 580]);
    xlabel(ax, 'Static Thrust (Grams)', 'FontWeight', 'bold');
    ylabel(ax, 'Thrust Efficiency (g/W)', 'FontWeight', 'bold');
    grid(ax, 'on');
    hold(ax, 'on');
    
    % Summary Table
    tbl = uitable(fig, 'Position', [820, 30, 420, 580], ...
        'ColumnName', {'Motor', 'Prop', 'Thrust (g)', 'Eff (g/W)', 'Watts'}, ...
        'ColumnWidth', {110, 85, 80, 70, 60}, ...
        'RowName', []);
    
    % Bind Callbacks
    diam_dd.ValueChangedFcn = @(~,~) update_dashboard();
    min_box.ValueChangedFcn = @(~,~) update_dashboard();
    max_box.ValueChangedFcn = @(~,~) update_dashboard();
    sort_dd.ValueChangedFcn = @(~,~) update_dashboard();
    
    % First plot
    update_dashboard();
    
    % --- Callbacks & Render Engine ---
    function reset_filters()
        diam_dd.Value = 'All Diameters';
        min_box.Value = min_thrust_init;
        max_box.Value = max_thrust_init;
        update_dashboard();
    end

    function update_dashboard()
        min_t = min_box.Value;
        max_t = max_box.Value;
        
        if min_t > max_t
            status_lbl.Text = 'Min > Max error.';
            return;
        end
        
        % Filter by Thrust Range
        in_range = [raw_data.ThrustGrams] >= min_t & [raw_data.ThrustGrams] <= max_t;
        filtered = raw_data(in_range);
        
        % Filter by Propeller Diameter
        switch diam_dd.Value
            case '9-inch Only'
                is_diam = startsWith({filtered.PropSize}, '9x', 'IgnoreCase', true);
                filtered = filtered(is_diam);
            case '12-inch Only'
                is_diam = startsWith({filtered.PropSize}, '12x', 'IgnoreCase', true);
                filtered = filtered(is_diam);
        end
        
        status_lbl.Text = sprintf('%d of %d matches', length(filtered), length(raw_data));
        cla(ax);
        
        if isempty(filtered)
            tbl.Data = {};
            return;
        end
        
        % Sort Data
        switch sort_dd.Value
            case 'Thrust: High to Low'
                [~, sort_idx] = sort([filtered.ThrustGrams], 'descend');
            case 'Thrust: Low to High'
                [~, sort_idx] = sort([filtered.ThrustGrams], 'ascend');
            case 'Eff: High to Low'
                [~, sort_idx] = sort([filtered.EffGramsPerW], 'descend');
        end
        filtered = filtered(sort_idx);
        
        % Update Table Data
        tbl_cells = cell(length(filtered), 5);
        for k = 1:length(filtered)
            tbl_cells{k, 1} = filtered(k).Motor;
            tbl_cells{k, 2} = filtered(k).PropSize;
            tbl_cells{k, 3} = sprintf('%.1f', filtered(k).ThrustGrams);
            tbl_cells{k, 4} = sprintf('%.2f', filtered(k).EffGramsPerW);
            tbl_cells{k, 5} = sprintf('%.1f', filtered(k).InputWatts);
        end
        tbl.Data = tbl_cells;
        
        % Plotting: Distinct series per motor with safe DataTip formatting
        unique_motors = unique({filtered.Motor}, 'stable');
        color_palette = lines(length(unique_motors));
        
        for m_idx = 1:length(unique_motors)
            mot = unique_motors{m_idx};
            sub_idx = strcmp({filtered.Motor}, mot);
            mot_sub = filtered(sub_idx);
            
            x_thrust = [mot_sub.ThrustGrams];
            y_eff = [mot_sub.EffGramsPerW];
            
            s = scatter(ax, x_thrust, y_eff, 75, color_palette(m_idx, :), 'filled', ...
                'DisplayName', mot, 'MarkerEdgeColor', [0.2, 0.2, 0.2]);
            
            % Robust string array conversion for DataTip rows
            s.DataTipTemplate.DataTipRows(1) = dataTipTextRow('Thrust (g)', x_thrust, '%.1f');
            s.DataTipTemplate.DataTipRows(2) = dataTipTextRow('Eff (g/W)', y_eff, '%.2f');
            
            % Append custom fields using string arrays
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Motor', string({mot_sub.Motor}));
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Prop', string({mot_sub.PropSize}));
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Manf', string({mot_sub.PropManf}));
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Thrust (oz)', [mot_sub.ThrustOunces], '%.2f');
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Power (W)', [mot_sub.InputWatts], '%.1f');
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Current (A)', [mot_sub.MotorAmps], '%.2f');
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('RPM', [mot_sub.PropRPM], '%d');
            s.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Pitch Speed', [mot_sub.PitchSpeed], '%.1f mph');
        end
        
        legend(ax, 'Location', 'northeastoutside', 'Interpreter', 'none');
        title(ax, sprintf('BadAss 4S: Thrust vs. Efficiency (%s)', diam_dd.Value));
    end
end

% --- Helper Parser ---
function data = parse_consolidated_file(filepath)
    data = struct('Motor', {}, 'PropManf', {}, 'PropSize', {}, 'MotorAmps', {}, ...
                  'InputWatts', {}, 'PropRPM', {}, 'PitchSpeed', {}, ...
                  'ThrustGrams', {}, 'ThrustOunces', {}, 'EffGramsPerW', {});
    
    fid = fopen(filepath, 'r');
    if fid == -1
        return;
    end
    
    count = 1;
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if startsWith(line, '=') || startsWith(line, '-') || startsWith(line, 'Motor') || line == ""
            continue;
        end
        
        parts = strtrim(split(line, '|'));
        if length(parts) >= 10
            try
                data(count).Motor = parts{1};
                data(count).PropManf = parts{2};
                data(count).PropSize = parts{3};
                data(count).MotorAmps = str2double(parts{4});
                data(count).InputWatts = str2double(parts{5});
                data(count).PropRPM = str2double(parts{6});
                data(count).PitchSpeed = str2double(parts{7});
                data(count).ThrustGrams = str2double(parts{8});
                data(count).ThrustOunces = str2double(parts{9});
                data(count).EffGramsPerW = str2double(parts{10});
                count = count + 1;
            catch
                % Skip malformed lines
            end
        end
    end
    fclose(fid);
end