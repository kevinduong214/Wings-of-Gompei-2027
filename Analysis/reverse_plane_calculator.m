function plane_3d_custom_axes()
    % Create the main UI Figure
    fig = uifigure('Name', 'Custom 3D Wing Chord Surface', 'Position', [100 100 900 650]);

    % --- Dropdown Selectors ---
    uilabel(fig, 'Position', [20 600 200 22], 'Text', 'Select Axes:', 'FontWeight', 'bold');
    
    options = {'Fuselage Chord', 'Fuselage Width', 'Wingspan', ...
               'Target Cube Load', 'Weight', 'Bottle Diameter'};
           
    uilabel(fig, 'Position', [20 570 50 22], 'Text', 'X-Axis:');
    dd_x = uidropdown(fig, 'Items', options, 'Position', [80 570 150 22], 'Value', 'Fuselage Chord');
    
    uilabel(fig, 'Position', [20 540 50 22], 'Text', 'Y-Axis:');
    dd_y = uidropdown(fig, 'Items', options, 'Position', [80 540 150 22], 'Value', 'Fuselage Width');

    % --- Inputs Panel (Scalars) ---
    uilabel(fig, 'Position', [20 490 200 22], 'Text', 'Constant Values:', 'FontWeight', 'bold');
    uilabel(fig, 'Position', [20 470 200 22], 'Text', '(Ignored if chosen as an axis)', 'FontSize', 10, 'FontColor', [0.5 0.5 0.5]);

    uilabel(fig, 'Position', [20 430 150 22], 'Text', 'Target Cube Load:');
    edt_cubeload = uieditfield(fig, 'numeric', 'Position', [150 430 80 22], 'Value', 6.0);

    uilabel(fig, 'Position', [20 390 150 22], 'Text', 'Weight (lbs):');
    edt_weight = uieditfield(fig, 'numeric', 'Position', [150 390 80 22], 'Value', 30);
    
    uilabel(fig, 'Position', [20 350 150 22], 'Text', 'Wingspan (in):');
    edt_wingspan = uieditfield(fig, 'numeric', 'Position', [150 350 80 22], 'Value', 95);

    uilabel(fig, 'Position', [20 310 150 22], 'Text', 'Bottle Dia. (in):');
    edt_bottle = uieditfield(fig, 'numeric', 'Position', [150 310 80 22], 'Value', 3.15);
    
    uilabel(fig, 'Position', [20 270 150 22], 'Text', 'Fuselage Chord (in):');
    edt_fuse_chord = uieditfield(fig, 'numeric', 'Position', [150 270 80 22], 'Value', 35);
    
    uilabel(fig, 'Position', [20 230 150 22], 'Text', 'Fuselage Width (in):');
    edt_fuse_width = uieditfield(fig, 'numeric', 'Position', [150 230 80 22], 'Value', 12);

    % --- 3D Axes ---
    ax = uiaxes(fig, 'Position', [270 50 600 550]);
    view(ax, -45, 30); 

    % Assign update functions
    dd_x.ValueChangedFcn = @(es,ed) updatePlot();
    dd_y.ValueChangedFcn = @(es,ed) updatePlot();
    edt_cubeload.ValueChangedFcn = @(es,ed) updatePlot();
    edt_weight.ValueChangedFcn = @(es,ed) updatePlot();
    edt_wingspan.ValueChangedFcn = @(es,ed) updatePlot();
    edt_bottle.ValueChangedFcn = @(es,ed) updatePlot();
    edt_fuse_chord.ValueChangedFcn = @(es,ed) updatePlot();
    edt_fuse_width.ValueChangedFcn = @(es,ed) updatePlot();

    updatePlot();

    function updatePlot()
        x_sel = dd_x.Value;
        y_sel = dd_y.Value;
        
        if strcmp(x_sel, y_sel)
            cla(ax);
            title(ax, 'Error: X and Y axes must be different variables.', 'Color', 'r');
            return;
        end

        % 1. Define default plotting ranges for whichever variables are selected
        ranges = struct(...
            'Fuselage_Chord', [5 100], ...
            'Fuselage_Width', [5 40], ...
            'Wingspan', [50 150], ...
            'Target_Cube_Load', [4 15], ...
            'Weight', [10 80], ...
            'Bottle_Diameter', [2 6]);
            
        x_key = strrep(x_sel, ' ', '_');
        y_key = strrep(y_sel, ' ', '_');

        % 2. Create the Meshgrid for the two selected axes
        [X, Y] = meshgrid(linspace(ranges.(x_key)(1), ranges.(x_key)(2), 100), ...
                          linspace(ranges.(y_key)(1), ranges.(y_key)(2), 100));

        % 3. Initialize all variables to their scalar text-box values
        fuse_chord = edt_fuse_chord.Value;
        fuse_w = edt_fuse_width.Value;
        b = edt_wingspan.Value;
        cubeload = edt_cubeload.Value;
        wt_lbs = edt_weight.Value;
        bottle_dia = edt_bottle.Value;
        
        % 4. Overwrite the scalar values with the grid matrices for the chosen axes
        switch x_sel
            case 'Fuselage Chord', fuse_chord = X;
            case 'Fuselage Width', fuse_w = X;
            case 'Wingspan', b = X;
            case 'Target Cube Load', cubeload = X;
            case 'Weight', wt_lbs = X;
            case 'Bottle Diameter', bottle_dia = X;
        end
        switch y_sel
            case 'Fuselage Chord', fuse_chord = Y;
            case 'Fuselage Width', fuse_w = Y;
            case 'Wingspan', b = Y;
            case 'Target Cube Load', cubeload = Y;
            case 'Weight', wt_lbs = Y;
            case 'Bottle Diameter', bottle_dia = Y;
        end

        % 5. Calculate Geometry (using element-wise operations for the matrices)
        wt_oz = wt_lbs .* 16;
        area_sqft = (wt_oz ./ cubeload).^(2/3);
        area_in2 = area_sqft .* 144;
        avg_chord = area_in2 ./ b;
        
        wing_chord = (avg_chord .* b - fuse_w .* fuse_chord) ./ (b - fuse_w);
        wing_chord(wing_chord <= 0) = NaN; % Remove invalid negative chords
        
        % 6. Apply the 24% Thickness Constraint Mask
        req_thickness = bottle_dia + 1;
        fuse_thick_pct = (req_thickness ./ fuse_chord) .* 100;
        wing_thick_pct = (req_thickness ./ wing_chord) .* 100;
        
        valid_mask = (fuse_thick_pct <= 24.0) & (wing_thick_pct <= 24.0);
        wing_chord(~valid_mask) = NaN; 

        % 7. Plot the surface
        cla(ax); 
        surf(ax, X, Y, wing_chord, 'EdgeColor', 'none');
        
        % 8. Dynamically Crop Axes to Valid Data
        if any(valid_mask, 'all')
            min_x = min(X(valid_mask)); max_x = max(X(valid_mask));
            min_y = min(Y(valid_mask)); max_y = max(Y(valid_mask));
            
            if min_x < max_x, xlim(ax, [min_x, max_x]); end
            if min_y < max_y, ylim(ax, [min_y, max_y]); end
            
            title(ax, 'Required Wing Chord (Cropped to Valid Geometries)', 'Color', 'k');
        else
            title(ax, 'No Valid Solutions Found (24% Limit Exceeded)', 'Color', 'r');
            xlim(ax, [ranges.(x_key)(1) ranges.(x_key)(2)]);
            ylim(ax, [ranges.(y_key)(1) ranges.(y_key)(2)]);
        end

        % Labels
        xlabel(ax, x_sel);
        ylabel(ax, y_sel);
        zlabel(ax, 'Wing Chord (in)');
        
        colormap(ax, 'parula');
        colorbar(ax, 'Position', [820 150 15 300]);
        grid(ax, 'on');
    end
end