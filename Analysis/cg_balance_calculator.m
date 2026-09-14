function cg_balance_calculator_dark()
    % --- Main Figure Setup ---
    fig = uifigure('Name', 'Interactive CG & Balance Calculator', 'Position', [100 100 1000 750]);
    fig.Color = [0.1 0.1 0.1]; % True Dark Background

    % Define common styles for dark mode
    header_style = {'FontWeight', 'bold', 'FontSize', 14, 'FontColor', 'w'};
    section_style = {'FontWeight', 'bold', 'FontSize', 13, 'BackgroundColor', [0.1 0.1 0.1], 'FontColor', [0.3 0.7 1.0]};
    error_style = {'FontWeight', 'bold', 'FontSize', 13, 'FontColor', [1 0.3 0.3]};
    
    label_bg = [0.1 0.1 0.1]; label_fg = 'w';
    edit_bg = [0.2 0.2 0.2]; edit_fg = 'w';
    
    % --- Structure Data ---
    current_wts = struct('wing_side', 5.0, 'fuse', 6.0, 'boom', 1.5, 'emp', 2.0);

    % ==========================================
    % LEFT PANEL: INPUTS
    % ==========================================
    pan_in = uipanel(fig, 'Title', 'Geometry & Weights', 'FontSize', 14, 'FontWeight', 'bold', ...
                     'Position', [10 130 280 610], 'BackgroundColor', [0.1 0.1 0.1], 'ForegroundColor', 'w');
                 
    lbl_w = 120; edt_w = 90; col1 = 15; col2 = 150;
    
    % [1] Wings
    uilabel(pan_in, 'Position', [10 580 200 22], 'Text', '1. Wings', section_style{:});
    uilabel(pan_in, 'Position', [col1 550 lbl_w 22], 'Text', 'Wingspan (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_span = uieditfield(pan_in, 'numeric', 'Position', [col2 550 edt_w 22], 'Value', 95, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_in, 'Position', [col1 520 lbl_w 22], 'Text', 'Chord (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_wing_c = uieditfield(pan_in, 'numeric', 'Position', [col2 520 edt_w 22], 'Value', 12, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_in, 'Position', [col1 490 lbl_w 22], 'Text', 'LE Offset (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_wing_offset = uieditfield(pan_in, 'numeric', 'Position', [col2 490 edt_w 22], 'Value', 8, 'BackgroundColor', edit_bg, 'FontColor', edit_fg); 
    uilabel(pan_in, 'Position', [col1 460 lbl_w 22], 'Text', 'Weight / Side (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_wing_side = uieditfield(pan_in, 'numeric', 'Position', [col2 460 edt_w 22], 'Value', current_wts.wing_side, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_in, 'Position', [col1 430 lbl_w 22], 'Text', 'Mass CG (% chord):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_wing_cg = uieditfield(pan_in, 'numeric', 'Position', [col2 430 edt_w 22], 'Value', 20, 'Limits', [0 100], 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % [2] Fuselage
    uilabel(pan_in, 'Position', [10 390 200 22], 'Text', '2. Fuselage', section_style{:});
    uilabel(pan_in, 'Position', [col1 360 lbl_w 22], 'Text', 'Width (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_fuse_w = uieditfield(pan_in, 'numeric', 'Position', [col2 360 edt_w 22], 'Value', 12, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_in, 'Position', [col1 330 lbl_w 22], 'Text', 'Chord (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_fuse_c = uieditfield(pan_in, 'numeric', 'Position', [col2 330 edt_w 22], 'Value', 20, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_in, 'Position', [col1 300 lbl_w 22], 'Text', 'Weight (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_fuse = uieditfield(pan_in, 'numeric', 'Position', [col2 300 edt_w 22], 'Value', current_wts.fuse, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_in, 'Position', [col1 270 lbl_w 22], 'Text', 'Mass CG (% chord):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_fuse_cg = uieditfield(pan_in, 'numeric', 'Position', [col2 270 edt_w 22], 'Value', 10, 'Limits', [0 100], 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % [3] Boom
    uilabel(pan_in, 'Position', [10 230 200 22], 'Text', '3. Boom', section_style{:});
    uilabel(pan_in, 'Position', [col1 200 lbl_w 22], 'Text', 'Length (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_boom_l = uieditfield(pan_in, 'numeric', 'Position', [col2 200 edt_w 22], 'Value', 20, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_in, 'Position', [col1 170 lbl_w 22], 'Text', 'Weight (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_boom = uieditfield(pan_in, 'numeric', 'Position', [col2 170 edt_w 22], 'Value', current_wts.boom, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % [4] Empennage
    uilabel(pan_in, 'Position', [10 130 200 22], 'Text', '4. Empennage', section_style{:});
    uilabel(pan_in, 'Position', [col1 100 lbl_w 22], 'Text', 'Weight (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_emp = uieditfield(pan_in, 'numeric', 'Position', [col2 100 edt_w 22], 'Value', current_wts.emp, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % ==========================================
    % RIGHT PANEL: VISUALIZATION
    % ==========================================
    ax = uiaxes(fig, 'Position', [300 130 690 610]);
    ax.BackgroundColor = [0.1 0.1 0.1];
    ax.XColor = 'w'; ax.YColor = 'w';
    title(ax, 'Top-Down Balance Sketch', 'FontSize', 16, 'Color', 'w');
    ax.YTickLabel = []; ax.XTickLabel = []; 
    ax.Interactions = []; 
    axis(ax, 'equal'); hold(ax, 'on');

    % Reverted Graphics Objects (White EdgeColors to pop on black background)
    g_fuse = fill(ax, [0 0 0 0], [0 0 0 0], [0.4 0.8 0.4], 'EdgeColor', 'w'); % Green
    g_boom = plot(ax, [0 0], [0 0], 'Color', [1 0.5 0], 'LineWidth', 4); % Orange
    g_wing = fill(ax, [0 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0], [0.9 0.3 0.3], 'EdgeColor', 'w'); % Red
    g_emp = fill(ax, [0 0 0 0], [0 0 0 0], [1 0.6 0.8], 'EdgeColor', 'w'); % Pink

    % Reverted Aerodynamic Lift Markers (Blue)
    g_sym_aero_cg = scatter(ax, NaN, NaN, 250, 'bd', 'Filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5); 
    g_sym_w_wing = scatter(ax, NaN, NaN, 60, 'bx', 'LineWidth', 2); 
    g_sym_fuse = scatter(ax, NaN, NaN, 60, 'bo', 'LineWidth', 2); 

    % Reverted Mass Markers (Black crosses, Yellow CG target)
    g_sym_m_parts = scatter(ax, NaN, NaN, 60, 'k+', 'LineWidth', 2); % Black crosses for subsystem masses
    g_sym_mass_cg = scatter(ax, NaN, NaN, 200, 'ko', 'Filled', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5); 

    % ==========================================
    % BOTTOM PANEL: OUTPUTS & WARNINGS
    % ==========================================
    pan_out = uipanel(fig, 'Position', [10 10 980 110], 'BackgroundColor', [0.1 0.1 0.1], 'ForegroundColor', 'w');
    
    lbl_w_gross = uilabel(pan_out, 'Position', [20 80 300 22], header_style{:});
    lbl_areas = uilabel(pan_out, 'Position', [350 80 600 22], 'Text', 'Area:', 'FontSize', 13, 'FontColor', 'w');
    
    lbl_mass_cg = uilabel(pan_out, 'Position', [20 45 600 22], header_style{:}, 'FontColor', 'y');
    lbl_aero_cg = uilabel(pan_out, 'Position', [20 15 600 22], header_style{:}, 'FontColor', [0.4 0.7 1]);
    
    lbl_w_error = uilabel(pan_out, 'Position', [550 45 400 22], error_style{:}, 'Visible', 'off');

    % --- Callbacks ---
    inputs = {edt_span, edt_fuse_w, edt_fuse_c, edt_wing_c, edt_wing_offset, edt_boom_l, ...
              edt_w_wing_side, edt_w_fuse, edt_w_boom, edt_w_emp, ...
              edt_wing_cg, edt_fuse_cg};
    for i=1:length(inputs), inputs{i}.ValueChangedFcn = @(es,ed) runUpdate(); end

    % Initial Run
    runUpdate();

    function runUpdate()
        % 1. Check Weights
        w_wing = edt_w_wing_side.Value;
        w_fuse = edt_w_fuse.Value;
        w_boom = edt_w_boom.Value;
        w_emp = edt_w_emp.Value;
        wt_total = (2*w_wing + w_fuse + w_boom + w_emp);
        
        if wt_total > 20
            lbl_w_error.Visible = 'on'; 
            lbl_w_error.Text = '⚠ Limit Exceeded! Reverting to keep gross weight ≤ 20 lbs.';
            pause(1.5); 
            edt_w_wing_side.Value = current_wts.wing_side;
            edt_w_fuse.Value = current_wts.fuse;
            edt_w_boom.Value = current_wts.boom;
            edt_w_emp.Value = current_wts.emp;
            lbl_w_error.Visible = 'off';
            return; 
        else
            current_wts.wing_side = w_wing; current_wts.fuse = w_fuse;
            current_wts.boom = w_boom; current_wts.emp = w_emp;
        end

        % 2. Update Geometry Visuals
        b = edt_span.Value; fw = edt_fuse_w.Value; fc = edt_fuse_c.Value; 
        wc = edt_wing_c.Value; bl = edt_boom_l.Value; emp_c = 10;
        
        % Read user-defined parameters
        wing_cg_pct = edt_wing_cg.Value / 100;
        fuse_cg_pct = edt_fuse_cg.Value / 100;
        wing_y_front = edt_wing_offset.Value;

        set(g_fuse, 'XData', [-fw/2, fw/2, fw/2, -fw/2], 'YData', [0, 0, fc, fc]); 
        set(g_boom, 'XData', [0, 0], 'YData', [fc, fc+bl]); 

        wing_x = [-b/2, -fw/2, -fw/2, fw/2, fw/2, b/2, b/2, -b/2];
        wing_y = [wing_y_front, wing_y_front, fc, fc, wing_y_front, wing_y_front, wing_y_front+wc, wing_y_front+wc];
        
        % Adjust visual overlap depending on offset
        if wing_y_front + wc > fc
            wing_y(3) = fc; wing_y(4) = fc; 
        end
        if wing_y_front < 0
            wing_y(3) = wing_y_front + wc; wing_y(4) = wing_y_front + wc; 
        else
             wing_y(3) = max(fc, wing_y_front+wc); wing_y(4) = max(fc, wing_y_front+wc);
        end

        set(g_wing, 'XData', [-b/2, b/2, b/2, -b/2], 'YData', [wing_y_front, wing_y_front, wing_y_front+wc, wing_y_front+wc]); 
        uistack(g_wing, 'bottom');

        set(g_emp, 'XData', [-fw/2, fw/2, fw/2, -fw/2], 'YData', [fc+bl, fc+bl, fc+bl+emp_c, fc+bl+emp_c]); 
        
        padding = max(b/2, fc+bl+emp_c) * 0.1;
        xlim(ax, [(-b/2) - padding, (b/2) + padding]);
        ylim(ax, [min(-padding, wing_y_front-padding), max((fc+bl+emp_c) + padding, wing_y_front+wc+padding)]);

        % 3. Calculate Aerodynamic Lift Center
        fuse_lift_y = 0.225 * fc; 
        wing_lift_y = wing_y_front + (0.225 * wc); 
        a_wing = wc * (b - fw); a_fuse = fc * fw; a_total = a_wing + a_fuse;
        aero_cg_y = ((a_fuse/a_total) * fuse_lift_y) + ((a_wing/a_total) * wing_lift_y);
                      
        set(g_sym_aero_cg, 'XData', 0, 'YData', aero_cg_y); 
        set(g_sym_fuse, 'XData', 0, 'YData', fuse_lift_y); 
        set(g_sym_w_wing, 'XData', [-b/4, b/4], 'YData', [wing_lift_y, wing_lift_y]); 

        % 4. Calculate True Mass CG
        y_fuse_m = fuse_cg_pct * fc;
        y_wing_m = wing_y_front + (wing_cg_pct * wc);
        y_boom_m = fc + (bl / 2);
        y_emp_m = fc + bl + (emp_c / 2);

        mass_cg_y = (w_fuse*y_fuse_m + (2*w_wing)*y_wing_m + w_boom*y_boom_m + w_emp*y_emp_m) / wt_total;

        set(g_sym_m_parts, 'XData', [0, -b/4, b/4, 0, 0], 'YData', [y_fuse_m, y_wing_m, y_wing_m, y_boom_m, y_emp_m]);
        set(g_sym_mass_cg, 'XData', 0, 'YData', mass_cg_y);

        % 5. Update Readouts
        lbl_w_gross.Text = sprintf('Total Gross Weight: %.2f lbs', wt_total);
        lbl_areas.Text = sprintf('Lifting Area: Wing = %.0f in² | Fuse = %.0f in² | Total = %.0f in²', a_wing, a_fuse, a_total);
        lbl_mass_cg.Text = sprintf('True Mass CG (Yellow Target): %.2f inches aft', mass_cg_y);
        lbl_aero_cg.Text = sprintf('Aero Lift Center (Blue Diamond): %.2f inches aft', aero_cg_y);
    end
end