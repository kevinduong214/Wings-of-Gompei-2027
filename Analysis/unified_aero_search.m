function unified_aero_search()
% UNIFIED_AERO_SEARCH Run this file, then click Search CG matches.
% Hard constraints: span = 95 in, cube loading <= 7, fuse width <= 40 in.
% Fuse chord >= wing chord; abs(wing TE - fuse TE) <= 7 in.
% Wing TE = wing LE offset + wing chord; fuse TE = fuse chord.
% Search all points on user-selected grids; solve wing offset continuously.
% Current component weights and CG percentages remain fixed during a search.
% Model matches original: area-weighted 22.5%-chord wing/fuselage centers,
% tail mass included but tail aerodynamic forces/moments not modeled.
% A match is a model balance result, not a trim or stability validation.

    % --- Main Figure Setup ---
    fig = uifigure('Name', 'Unified Aero Design & Balance Calculator', 'Position', [50 50 1400 850]);
    fig.Color = [0.1 0.1 0.1]; % True Dark Background

    searchDialog = [];
    fig.DeleteFcn = @closeSearchWithMain;

    % Define common styles
    header_style = {'FontWeight', 'bold', 'FontSize', 14, 'FontColor', 'w'};
    section_style = {'FontWeight', 'bold', 'FontSize', 13, 'BackgroundColor', [0.1 0.1 0.1], 'FontColor', [0.3 0.7 1.0]};
    error_style = {'FontWeight', 'bold', 'FontSize', 13, 'FontColor', [1 0.3 0.3]};
    
    label_bg = [0.1 0.1 0.1]; label_fg = 'w';
    edit_bg = [0.2 0.2 0.2]; edit_fg = 'w';
    
    % Initial Structure Data for the 19.5 lb setup
    current_wts = struct('wing_side', 5.0, 'fuse', 6.0, 'boom', 1.5, 'emp', 2.0);

    % =====================================================================
    % PANEL 1: DESIGN SYNTHESIS (Left Side)
    % =====================================================================
    pan_syn = uipanel(fig, 'Title', '1. DESIGN SYNTHESIS: Generate Geometry', ...
        'Position', [10 10 380 830], 'BackgroundColor', label_bg, 'ForegroundColor', 'w', ...
        'FontWeight', 'bold', 'FontSize', 14);

    uilabel(pan_syn, 'Position', [10 770 360 22], 'Text', 'Define Axes (Plot Range defined in code):', 'FontWeight', 'bold', 'FontColor', [0.7 0.7 0.7]);
    uilabel(pan_syn, 'Position', [10 740 60 22], 'Text', 'X-Axis:', 'FontColor', 'w');
    
    axis_opts = {'Fuselage Chord', 'Fuselage Width', 'Target Cube Load', 'Weight'};
    dd_x = uidropdown(pan_syn, 'Items', axis_opts, 'Position', [80 740 160 22], 'Value', 'Fuselage Chord', 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    
    uilabel(pan_syn, 'Position', [10 710 60 22], 'Text', 'Y-Axis:', 'FontColor', 'w');
    dd_y = uidropdown(pan_syn, 'Items', axis_opts, 'Position', [80 710 160 22], 'Value', 'Fuselage Width', 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    
    uilabel(pan_syn, 'Position', [10 660 360 22], 'Text', 'Set Constant Inputs (For plot point):', 'FontWeight', 'bold', 'FontColor', [0.7 0.7 0.7]);
    
    edt_w = 90; col1 = 10; col2 = 150;
    uilabel(pan_syn, 'Position', [col1 630 140 22], 'Text', 'Target Cube Load:', 'FontColor', 'w');
    edt_syn_cubeload = uieditfield(pan_syn, 'numeric', 'Position', [col2 630 edt_w 22], 'Value', 6.0, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    
    uilabel(pan_syn, 'Position', [col1 600 140 22], 'Text', 'Total Weight (lbs):', 'FontColor', 'w');
    edt_syn_weight = uieditfield(pan_syn, 'numeric', 'Position', [col2 600 edt_w 22], 'Value', 19.5, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    
    uilabel(pan_syn, 'Position', [col1 570 140 22], 'Text', 'Wingspan (in):', 'FontColor', 'w');
    edt_syn_span = uieditfield(pan_syn, 'numeric', 'Position', [col2 570 edt_w 22], 'Value', 95, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    
    uilabel(pan_syn, 'Position', [col1 540 140 22], 'Text', 'Fuse Width (in):', 'FontColor', 'w');
    edt_syn_fuse_w = uieditfield(pan_syn, 'numeric', 'Position', [col2 540 edt_w 22], 'Value', 12, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    
    uilabel(pan_syn, 'Position', [col1 510 140 22], 'Text', 'Fuse Chord (in):', 'FontColor', 'w');
    edt_syn_fuse_c = uieditfield(pan_syn, 'numeric', 'Position', [col2 510 edt_w 22], 'Value', 20, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % Button to pipe basic geometry to the Balance section
    hBtn_apply_syn = uibutton(pan_syn, 'Text', 'Apply Point to Balance ->', ...
        'Position', [col2+100 510 120 110], 'FontWeight', 'bold', 'ButtonPushedFcn', @applySynthesisPoint);

    % 3D Axes area
    ax_syn = uiaxes(pan_syn, 'Position', [10 10 360 480]);
    ax_syn.BackgroundColor = [0.1 0.1 0.1];
    ax_syn.XColor = 'w'; ax_syn.YColor = 'w'; ax_syn.ZColor = 'w';
    view(ax_syn, -45, 30);
    grid(ax_syn, 'on');

    % =====================================================================
    % PANEL 2: AIRPLANE BALANCE & 'CG' CALCULATOR (Right Side)
    % =====================================================================
    pan_bal = uipanel(fig, 'Title', '2. AIRPLANE BALANCE: Visual ''CG'' Checker', ...
        'Position', [400 10 990 830], 'BackgroundColor', label_bg, 'ForegroundColor', 'w', ...
        'FontWeight', 'bold', 'FontSize', 14);

    % --- Sub-Panel: Detailed Inputs ---
    pan_bal_in = uipanel(pan_bal, 'Position', [10 140 280 650], 'BackgroundColor', label_bg, 'ForegroundColor', 'w');
    
    % [1] Wings
    uilabel(pan_bal_in, 'Position', [10 610 200 22], 'Text', '1. Wings', section_style{:});
    uilabel(pan_bal_in, 'Position', [col1 580 130 22], 'Text', 'Wingspan (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_bal_span = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 580 edt_w 22], 'Value', 95, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    
    % *Auto-Calculated Output* based on Target Cube Load & Weight
    uilabel(pan_bal_in, 'Position', [col1 550 140 22], 'Text', 'Req. Wing Chord (in):', 'FontWeight', 'bold', 'BackgroundColor', label_bg, 'FontColor', [1 0.8 0]);
    lbl_bal_wing_c_res = uilabel(pan_bal_in, 'Position', [col2 550 edt_w 22], 'Text', '0.0', 'FontWeight', 'bold', 'FontColor', 'k', 'BackgroundColor', [1 0.8 0]);
    
    uilabel(pan_bal_in, 'Position', [col1 520 130 22], 'Text', 'LE Offset (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_wing_offset = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 520 edt_w 22], 'Value', 8, 'BackgroundColor', edit_bg, 'FontColor', edit_fg); 
    uilabel(pan_bal_in, 'Position', [col1 490 130 22], 'Text', 'Weight / Side (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_wing_side = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 490 edt_w 22], 'Value', current_wts.wing_side, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_bal_in, 'Position', [col1 460 130 22], 'Text', 'Mass CG (% chord):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_wing_cg = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 460 edt_w 22], 'Value', 20, 'Limits', [0 100], 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % [2] Fuselage
    uilabel(pan_bal_in, 'Position', [10 410 200 22], 'Text', '2. Fuselage', section_style{:});
    uilabel(pan_bal_in, 'Position', [col1 380 130 22], 'Text', 'Width (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_bal_fuse_w = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 380 edt_w 22], 'Value', 12, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_bal_in, 'Position', [col1 350 130 22], 'Text', 'Chord (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_bal_fuse_c = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 350 edt_w 22], 'Value', 20, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_bal_in, 'Position', [col1 320 130 22], 'Text', 'Weight (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_fuse = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 320 edt_w 22], 'Value', current_wts.fuse, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_bal_in, 'Position', [col1 290 130 22], 'Text', 'Mass CG (% chord):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_fuse_cg = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 290 edt_w 22], 'Value', 10, 'Limits', [0 100], 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % [3] Boom
    uilabel(pan_bal_in, 'Position', [10 240 200 22], 'Text', '3. Boom', section_style{:});
    uilabel(pan_bal_in, 'Position', [col1 210 130 22], 'Text', 'Length (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_boom_l = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 210 edt_w 22], 'Value', 20, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_bal_in, 'Position', [col1 180 130 22], 'Text', 'Weight (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_boom = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 180 edt_w 22], 'Value', current_wts.boom, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % [4] Empennage
    uilabel(pan_bal_in, 'Position', [10 130 200 22], 'Text', '4. Empennage', section_style{:});
    uilabel(pan_bal_in, 'Position', [col1 100 130 22], 'Text', 'Chord (in):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_emp_c = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 100 edt_w 22], 'Value', 10, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_bal_in, 'Position', [col1 70 130 22], 'Text', 'Weight (lbs):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_w_emp = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 70 edt_w 22], 'Value', current_wts.emp, 'BackgroundColor', edit_bg, 'FontColor', edit_fg);
    uilabel(pan_bal_in, 'Position', [col1 40 130 22], 'Text', 'Mass CG (% chord):', 'BackgroundColor', label_bg, 'FontColor', label_fg);
    edt_emp_cg = uieditfield(pan_bal_in, 'numeric', 'Position', [col2 40 edt_w 22], 'Value', 50, 'Limits', [0 100], 'BackgroundColor', edit_bg, 'FontColor', edit_fg);

    % --- Sub-Panel: Sketch Visualizer ---
    ax_bal = uiaxes(pan_bal, 'Position', [300 140 680 650]);
    ax_bal.BackgroundColor = [0.1 0.1 0.1];
    ax_bal.XColor = 'w'; ax_bal.YColor = 'w';
    title(ax_bal, 'Top-Down Balance Sketch (Geometry dynamically scales)', 'FontSize', 15, 'Color', 'w');
    ax_bal.YTickLabel = []; ax_bal.XTickLabel = []; 
    ax_bal.Interactions = []; 
    axis(ax_bal, 'equal'); hold(ax_bal, 'on');

    % Graphics Objects
    g_fuse = fill(ax_bal, [0 0 0 0], [0 0 0 0], [0.4 0.8 0.4], 'EdgeColor', 'w'); % Green
    g_boom = plot(ax_bal, [0 0], [0 0], 'Color', [1 0.5 0], 'LineWidth', 4); % Orange
    g_wing = fill(ax_bal, [0 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0], [0.9 0.3 0.3], 'EdgeColor', 'w'); % Red
    g_emp = fill(ax_bal, [0 0 0 0], [0 0 0 0], [1 0.6 0.8], 'EdgeColor', 'w'); % Pink

    g_sym_aero_cg = scatter(ax_bal, NaN, NaN, 250, 'bd', 'Filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5); 
    g_sym_w_wing = scatter(ax_bal, NaN, NaN, 60, 'bx', 'LineWidth', 2); 
    g_sym_fuse = scatter(ax_bal, NaN, NaN, 60, 'bo', 'LineWidth', 2); 
    g_sym_m_parts = scatter(ax_bal, NaN, NaN, 60, 'w+', 'LineWidth', 2); % White crosses for parts
    g_sym_mass_cg = scatter(ax_bal, NaN, NaN, 200, 'ko', 'Filled', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5); 

    % --- Sub-Panel: Outputs ---
    pan_bal_out = uipanel(pan_bal, 'Position', [10 10 970 120], 'BackgroundColor', label_bg, 'ForegroundColor', 'w');
    
    lbl_w_gross = uilabel(pan_bal_out, 'Position', [20 85 300 22], header_style{:});
    lbl_w_error = uilabel(pan_bal_out, 'Position', [350 85 500 22], error_style{:}, 'Visible', 'off');
    
    lbl_areas = uilabel(pan_bal_out, 'Position', [20 50 600 22], 'Text', 'Area:', 'FontSize', 13, 'FontColor', [0.7 0.7 0.7]);
    
    lbl_mass_cg = uilabel(pan_bal_out, 'Position', [500 50 450 22], header_style{:}, 'FontColor', 'y');
    lbl_aero_cg = uilabel(pan_bal_out, 'Position', [500 20 450 22], header_style{:}, 'FontColor', [0.4 0.7 1]);

    % =====================================================================
    % DEFINE THE INTERACTIVE LOOPS / CALLBACKS
    % =====================================================================
    design_fields = {edt_syn_cubeload, edt_syn_weight, edt_syn_span, edt_syn_fuse_w, edt_syn_fuse_c, dd_x, dd_y};
    for i=1:length(design_fields), design_fields{i}.ValueChangedFcn = @(es,ed) runSynthesis(); end

    balance_fields = {edt_bal_span, edt_bal_fuse_w, edt_bal_fuse_c, edt_wing_offset, edt_boom_l, edt_emp_c, ...
                      edt_w_wing_side, edt_w_fuse, edt_w_boom, edt_w_emp, ...
                      edt_wing_cg, edt_fuse_cg, edt_emp_cg};
    for i=1:length(balance_fields), balance_fields{i}.ValueChangedFcn = @(es,ed) updateBalance(); end
    
    % Ensure target cube load updates balance immediately when changed
    edt_syn_cubeload.ValueChangedFcn = @(es,ed) updateAll(); 

    % Apply constraints to manual controls as well as the search.
    edt_syn_span.Editable = 'off'; edt_bal_span.Editable = 'off';
    edt_syn_cubeload.Limits = [0 7];
    edt_syn_cubeload.LowerLimitInclusive = 'off';
    for h = [edt_syn_fuse_w edt_bal_fuse_w]
        h.Limits = [0 40]; h.LowerLimitInclusive = 'off';
    end
    for h = [edt_syn_fuse_c edt_bal_fuse_c edt_emp_c edt_syn_weight]
        h.Limits = [0 Inf]; h.LowerLimitInclusive = 'off';
    end
    edt_syn_weight.Limits = [0 20];
    for h = [edt_boom_l edt_w_wing_side edt_w_fuse edt_w_boom edt_w_emp]
        h.Limits = [0 Inf];
    end
    uibutton(pan_bal_out, 'Text', 'Search CG matches...', ...
        'Position', [20 15 180 27], 'ButtonPushedFcn', @openSearch);

    % Initial Run
    updateAll();

    function updateAll()
        runSynthesis();
        updateBalance();
    end

    % =====================================================================
    % CALCULATION ENGINES
    % =====================================================================
    function runSynthesis()
        x_sel = dd_x.Value; y_sel = dd_y.Value;
        if strcmp(x_sel, y_sel)
            cla(ax_syn); title(ax_syn, 'Error: X and Y axes must be different.', 'Color', 'r'); return; 
        end
        
        ranges = struct('Fuselage_Chord', [5 50], 'Fuselage_Width', [5 40], ...
            'Wingspan', [95 95], 'Target_Cube_Load', [4 7], 'Weight', [10 20]);
        x_key = strrep(x_sel, ' ', '_'); y_key = strrep(y_sel, ' ', '_');
        [X_mesh, Y_mesh] = meshgrid(linspace(ranges.(x_key)(1), ranges.(x_key)(2), 50), linspace(ranges.(y_key)(1), ranges.(y_key)(2), 50));
        
        w_cubeload = edt_syn_cubeload.Value; w_wt = edt_syn_weight.Value;
        w_span = edt_syn_span.Value; w_fuse_w = edt_syn_fuse_w.Value; w_fuse_c = edt_syn_fuse_c.Value; 
        
        switch x_sel
            case 'Fuselage Width', w_fuse_w = X_mesh; case 'Wingspan', w_span = X_mesh;
            case 'Target Cube Load', w_cubeload = X_mesh; case 'Weight', w_wt = X_mesh;
            case 'Fuselage Chord', w_fuse_c = X_mesh;
        end
        switch y_sel
            case 'Fuselage Width', w_fuse_w = Y_mesh; case 'Wingspan', w_span = Y_mesh;
            case 'Target Cube Load', w_cubeload = Y_mesh; case 'Weight', w_wt = Y_mesh;
            case 'Fuselage Chord', w_fuse_c = Y_mesh;
        end
        
        w_wt_oz = w_wt .* 16;
        w_area_sqft = (w_wt_oz ./ w_cubeload).^(2/3);
        w_area_in2 = w_area_sqft .* 144;
        w_avg_chord = w_area_in2 ./ w_span;
        w_wing_chord_surf = (w_avg_chord .* w_span - w_fuse_w .* w_fuse_c) ./ (w_span - w_fuse_w);
        
        w_wing_chord_surf(w_wing_chord_surf <= 0 | w_wing_chord_surf > w_fuse_c) = NaN;
        
        cla(ax_syn); surf(ax_syn, X_mesh, Y_mesh, w_wing_chord_surf, 'EdgeColor', 'none');
        xlabel(ax_syn, x_sel); ylabel(ax_syn, y_sel); zlabel(ax_syn, 'Required Wing Chord (in)');
        title(ax_syn, 'Design Synthesis: Required geometry', 'Color', 'w');
        colormap(ax_syn, 'parula');
        
        % Ensure Balance triggers if weight/cubeload were modified here
        updateBalance();
    end

    function applySynthesisPoint(~,~)
        % Flow basic synthesis geometry to the Balance panel
        edt_bal_span.Value = edt_syn_span.Value;
        edt_bal_fuse_w.Value = edt_syn_fuse_w.Value;
        edt_bal_fuse_c.Value = edt_syn_fuse_c.Value;
        updateBalance();
    end

    function updateBalance()
        % 1. Evaluate Current Gross Weight
        w_wing = edt_w_wing_side.Value;
        w_fuse = edt_w_fuse.Value;
        w_boom = edt_w_boom.Value;
        w_emp = edt_w_emp.Value;
        wt_total = (2*w_wing + w_fuse + w_boom + w_emp);
        
        if wt_total > 20 || wt_total <= 0
            lbl_w_error.Visible = 'on'; 
            lbl_w_error.Text = '⚠ Limit Exceeded! Gross weight must be > 0 and <= 20 lbs.';
            pause(1.5); 
            edt_w_wing_side.Value = current_wts.wing_side;
            edt_w_fuse.Value = current_wts.fuse;
            edt_w_boom.Value = current_wts.boom;
            edt_w_emp.Value = current_wts.emp;
            lbl_w_error.Visible = 'off';
            wt_total = (2*current_wts.wing_side + current_wts.fuse + current_wts.boom + current_wts.emp);
        else
            current_wts.wing_side = w_wing; current_wts.fuse = w_fuse;
            current_wts.boom = w_boom; current_wts.emp = w_emp;
        end

        % 2. Calculate Required Wing Chord based on Cube Load Target
        target_cl = edt_syn_cubeload.Value;
        b = edt_bal_span.Value; fw = edt_bal_fuse_w.Value; fc = edt_bal_fuse_c.Value; 
        
        wt_oz = wt_total * 16;
        req_area_sqft = (wt_oz / target_cl)^(2/3);
        req_area_in2 = req_area_sqft * 144;
        
        req_avg_chord = req_area_in2 / b;
        wc = (req_avg_chord * b - fw * fc) / (b - fw);
        
        if wc <= 0 || b <= fw
            lbl_bal_wing_c_res.Text = 'ERR: Math';
            return; % Geometry impossible
        end
        
        lbl_bal_wing_c_res.Text = sprintf('  %.2f', wc);

        % 3. Update Visuals
        bl = edt_boom_l.Value; emp_c = edt_emp_c.Value;
        wing_cg_pct = edt_wing_cg.Value / 100;
        fuse_cg_pct = edt_fuse_cg.Value / 100;
        emp_cg_pct = edt_emp_cg.Value / 100;
        wing_y_front = edt_wing_offset.Value;

        set(g_fuse, 'XData', [-fw/2, fw/2, fw/2, -fw/2], 'YData', [0, 0, fc, fc]); 
        set(g_boom, 'XData', [0, 0], 'YData', [fc, fc+bl]); 

        wing_y = [wing_y_front, wing_y_front, fc, fc, wing_y_front, wing_y_front, wing_y_front+wc, wing_y_front+wc];
        
        % Overlap clamping logic for clean rendering
        if wing_y_front + wc > fc, wing_y(3) = fc; wing_y(4) = fc; end
        if wing_y_front < 0, wing_y(3) = wing_y_front + wc; wing_y(4) = wing_y_front + wc; 
        else, wing_y(3) = max(fc, wing_y_front+wc); wing_y(4) = max(fc, wing_y_front+wc); end

        set(g_wing, 'XData', [-b/2, b/2, b/2, -b/2], 'YData', [wing_y_front, wing_y_front, wing_y_front+wc, wing_y_front+wc]); 
        uistack(g_wing, 'bottom');

        set(g_emp, 'XData', [-fw/2, fw/2, fw/2, -fw/2], 'YData', [fc+bl, fc+bl, fc+bl+emp_c, fc+bl+emp_c]); 
        
        padding = max(b/2, fc+bl+emp_c) * 0.15;
        xlim(ax_bal, [(-b/2) - padding, (b/2) + padding]);
        ylim(ax_bal, [min(-padding, wing_y_front-padding), max((fc+bl+emp_c) + padding, wing_y_front+wc+padding)]);

        % 4. Calculate Aerodynamic Lift Center
        fuse_lift_y = 0.225 * fc; 
        wing_lift_y = wing_y_front + (0.225 * wc); 
        a_wing = wc * (b - fw); a_fuse = fc * fw; a_total = a_wing + a_fuse;
        aero_cg_y = ((a_fuse/a_total) * fuse_lift_y) + ((a_wing/a_total) * wing_lift_y);
                      
        set(g_sym_aero_cg, 'XData', 0, 'YData', aero_cg_y); 
        set(g_sym_fuse, 'XData', 0, 'YData', fuse_lift_y); 
        set(g_sym_w_wing, 'XData', [-b/4, b/4], 'YData', [wing_lift_y, wing_lift_y]); 

        % 5. Calculate True Mass CG
        y_fuse_m = fuse_cg_pct * fc;
        y_wing_m = wing_y_front + (wing_cg_pct * wc);
        y_boom_m = fc + (bl / 2);
        y_emp_m = fc + bl + (emp_cg_pct * emp_c);

        mass_cg_y = (current_wts.fuse*y_fuse_m + (2*current_wts.wing_side)*y_wing_m + current_wts.boom*y_boom_m + current_wts.emp*y_emp_m) / wt_total;

        set(g_sym_m_parts, 'XData', [0, -b/4, b/4, 0, 0], 'YData', [y_fuse_m, y_wing_m, y_wing_m, y_boom_m, y_emp_m]);
        set(g_sym_mass_cg, 'XData', 0, 'YData', mass_cg_y);

        % 6. Update Readouts
        lbl_w_gross.Text = sprintf('Total Gross Wt: %.2f lbs', wt_total);
        lbl_areas.Text = sprintf('Area: Wing = %.0f in² | Fuse = %.0f in² | Total = %.0f in² | Target CL = %.1f', a_wing, a_fuse, a_total, target_cl);
        lbl_mass_cg.Text = sprintf('True Mass CG (Yellow Target): %.2f inches aft', mass_cg_y);
        lbl_aero_cg.Text = sprintf('Aero Lift Center (Blue Diamond): %.2f inches aft', aero_cg_y);
        % Display the current sketch, but explicitly flag invalid manual geometry.
        te_gap = abs(wing_y_front + wc - fc);
        violations = {};
        if wc > fc, violations{end+1} = 'Fuse chord < wing chord'; end
        if te_gap > 7, violations{end+1} = 'TE separation > 7 in'; end
        lbl_w_error.Visible = 'off';
        if ~isempty(violations)
            lbl_w_error.Text = ['INVALID: ' strjoin(violations, '; ')];
            lbl_w_error.Visible = 'on';
        end
    end
    function closeSearchWithMain(~,~)
        if ~isempty(searchDialog) && isvalid(searchDialog), delete(searchDialog); end
    end

    function openSearch(~,~)
        if ~isempty(searchDialog) && isvalid(searchDialog)
            figure(searchDialog); return;
        end
        dlg = uifigure('Name','Search all grid matches', 'Position',[30 80 1450 760]);
        searchDialog = dlg;
        uilabel(dlg,'Position',[15 715 1120 30], 'Text', ...
            'Span = 95 in | Cube load <= 7 | Fuse width <= 40 in | Fuse chord >= wing chord | Absolute TE gap <= 7 in');
        uilabel(dlg,'Position',[15 685 1120 25], 'Text', ...
            'Grid fields are [minimum, step, maximum]. Endpoints are included. Narrow ranges or increase steps for faster searches.');
        labels = {'Fuse width (in)','Fuse chord (in)','Cube load','Boom length (in)','Tail chord (in)'};
        defaults = [5 1 40; 5 1 50; 4 0.5 7; 10 5 40; 5 2.5 20];
        inputs = cell(5,3);
        for j=1:5
            y=650-(j-1)*35;
            uilabel(dlg,'Position',[15 y 140 22],'Text',labels{j});
            for k=1:3
                inputs{j,k}=uieditfield(dlg,'numeric','Position',[160+(k-1)*95 y 85 22], ...
                    'Value',defaults(j,k));
            end
        end
        uilabel(dlg,'Position',[470 650 260 22],'Text','Wing LE offset bounds (in aft of nose)');
        offLo=uieditfield(dlg,'numeric','Position',[750 650 90 22],'Value',-20);
        offHi=uieditfield(dlg,'numeric','Position',[850 650 90 22],'Value',50);
        uilabel(dlg,'Position',[470 615 260 22],'Text','Allowed |mass CG - lift center| (in)');
        tol=uieditfield(dlg,'numeric','Position',[750 615 90 22],'Value',0.05,'Limits',[0 Inf]);
        overlap=uicheckbox(dlg,'Position',[470 580 650 22],'Value',true, ...
            'Text','Require positive wing/fuselage chord overlap and wing ahead of tail');
        uilabel(dlg,'Position',[470 540 640 35],'Text', ...
            'Current masses/CG fractions held fixed. Original lift model omits tail lift and pitching moments.');
        status=uilabel(dlg,'Position',[15 455 1120 40],'Text','Set ranges, then run. Defaults are search assumptions you can edit.');
        tab=uitable(dlg,'Position',[15 95 680 350],'Data',table());
        preview=uiaxes(dlg,'Position',[710 95 720 350]);
        hold(preview,'on'); axis(preview,'equal'); grid(preview,'on');
        xlabel(preview,'Spanwise position (in)'); ylabel(preview,'Distance aft of nose (in)');
        title(preview,'Playback: yellow circle = mass CG; blue diamond = lift center');
        pvWing=patch(preview,nan(1,4),nan(1,4),[0.9 0.3 0.3]);
        pvFuse=patch(preview,nan(1,4),nan(1,4),[0.4 0.8 0.4]);
        pvBoom=plot(preview,NaN,NaN,'Color',[1 0.5 0],'LineWidth',3);
        pvTail=patch(preview,nan(1,4),nan(1,4),[1 0.6 0.8]);
        pvCG=scatter(preview,NaN,NaN,130,'y','filled','MarkerEdgeColor','k');
        pvLift=scatter(preview,NaN,NaN,100,'b','d','LineWidth',2);
        pageStart=1; pageSize=1000;
        playBtn=uibutton(dlg,'Position',[15 55 125 28],'Text','Play','ButtonPushedFcn',@togglePlayback);
        uibutton(dlg,'Position',[150 55 85 28],'Text','Previous','ButtonPushedFcn',@(~,~)stepMatch(-1));
        uibutton(dlg,'Position',[245 55 85 28],'Text','Next','ButtonPushedFcn',@(~,~)stepMatch(1));
        uilabel(dlg,'Position',[345 55 70 28],'Text','Go to #');
        jump=uieditfield(dlg,'numeric','Position',[415 55 95 28],'Value',1, ...
            'Limits',[1 Inf],'RoundFractionalValues','on','ValueChangedFcn',@jumpMatch);
        counter=uilabel(dlg,'Position',[530 55 895 28],'Text','No matches loaded.');
        uilabel(dlg,'Position',[530 15 45 28],'Text','FPS:');
        fpsInput=uieditfield(dlg,'numeric','Position',[575 15 90 28], ...
            'Value',3,'Limits',[0.1 1000],'ValueChangedFcn',@changeFPS, ...
            'Tooltip','Target frames per second (0.1 to 1000). Actual rate depends on rendering speed.');
        player=timer('ExecutionMode','fixedRate','Period',framePeriod(), ...
            'BusyMode','drop','TimerFcn',@advanceFrame,'ErrorFcn',@playbackError);
        dlg.DeleteFcn=@disposePlayback;
        % Dropped timer ticks delay playback; result rows are never skipped.

        results=table(); selected=1; snapshot=struct();
        runBtn=uibutton(dlg,'Position',[15 15 130 28],'Text','Run search','ButtonPushedFcn',@runSearch);
        uibutton(dlg,'Position',[160 15 180 28],'Text','Apply selected match','ButtonPushedFcn',@applyMatch);
        uibutton(dlg,'Position',[355 15 140 28],'Text','Export all to CSV','ButtonPushedFcn',@exportMatches);
        tab.CellSelectionCallback=@selectMatch;

        function runSearch(~,~)
            pausePlayback();
            try
                grids=cell(1,5);
                for jj=1:5
                    v=cellfun(@(h)h.Value,inputs(jj,:));
                    assert(all(isfinite(v)) && v(2)>0 && v(3)>=v(1), ...
                        'Each grid needs finite min <= max and step > 0.');
                    assert(v(1)>0, 'Geometry and cube loading must be positive.');
                    if jj==1, assert(v(3)<=40,'Fuselage width cannot exceed 40 in.'); end
                    if jj==3, assert(v(3)<=7,'Cube loading cannot exceed 7.'); end
                    assert((v(3)-v(1))/v(2)<=2e6,'Grid too large; increase step.');
                    grids{jj}=unique([v(1):v(2):v(3),v(3)]);
                end
                assert(isfinite(offLo.Value) && isfinite(offHi.Value) && offLo.Value<=offHi.Value, ...
                    'Offset bounds must be finite and ordered.');
                assert(isfinite(tol.Value),'Tolerance must be finite.');
                n=prod(cellfun(@numel,grids));
                assert(n<=2e6,'More than 2 million grid points. Narrow ranges or increase steps.');
                updateBalance();
                snapshot.weights=[current_wts.wing_side current_wts.fuse current_wts.boom current_wts.emp];
                snapshot.fractions=[edt_wing_cg.Value edt_fuse_cg.Value edt_emp_cg.Value]/100;
                runBtn.Enable='off'; status.Text=sprintf('Searching %g geometry combinations...',n); drawnow nocallbacks;
                results=solveGrid(grids,snapshot.weights,snapshot.fractions, ...
                    [offLo.Value offHi.Value],tol.Value,overlap.Value);
                selected=1;
            % Hold common axis limits so frame-to-frame geometry is comparable.
            if ~isempty(results)
                xlim(preview,[-55 55]);
                ylim(preview,[min(0,min(results.LE_Best_in))-5, ...
                    max(max(results.FuseChord_in+results.BoomLength_in+results.TailChord_in), ...
                    max(results.WingTE_in))+5]);
            end
                pageStart=0; refreshPage();
                if ~isempty(results), applyMatch([],[]); else, clearPreview(); end
                status.Text=sprintf('%d matching grid geometries. Playback visits all rows; table pages automatically; CSV exports all. LE_Min/Max give the full valid interval.',height(results));
                runBtn.Enable='on';
            catch err
                if isvalid(dlg)
                    runBtn.Enable='on'; uialert(dlg,err.message,'Search could not complete');
                end
            end
        end
        function selectMatch(~,evt)
            if ~isempty(evt.Indices)
                pausePlayback(); selected=pageStart+evt.Indices(1,1)-1;
                applyMatch([],[]);
            end
        end
        function applyMatch(~,~)
            if isempty(results), return; end
            r=results(selected,:);
            edt_syn_cubeload.Value=r.CubeLoad;
            edt_syn_fuse_w.Value=r.FuseWidth_in; edt_bal_fuse_w.Value=r.FuseWidth_in;
            edt_syn_fuse_c.Value=r.FuseChord_in; edt_bal_fuse_c.Value=r.FuseChord_in;
            edt_boom_l.Value=r.BoomLength_in; edt_emp_c.Value=r.TailChord_in;
            edt_wing_offset.Value=r.LE_Best_in;
            edt_w_wing_side.Value=snapshot.weights(1); edt_w_fuse.Value=snapshot.weights(2);
            edt_w_boom.Value=snapshot.weights(3); edt_w_emp.Value=snapshot.weights(4);
            edt_wing_cg.Value=100*snapshot.fractions(1); edt_fuse_cg.Value=100*snapshot.fractions(2);
            edt_emp_cg.Value=100*snapshot.fractions(3);
            edt_syn_weight.Value=sum(snapshot.weights.*[2 1 1 1]);
            % Avoid rebuilding the synthesis surface on every animation frame.
            if strcmp(player.Running,'on'), updateBalance(); else, updateAll(); end
            refreshPage(); jump.Value=selected;
            updateCounter();
            set(pvWing,'XData',[-47.5 47.5 47.5 -47.5], ...
                'YData',r.LE_Best_in+[0 0 r.WingChord_in r.WingChord_in]);
            set(pvFuse,'XData',r.FuseWidth_in/2*[-1 1 1 -1], ...
                'YData',[0 0 r.FuseChord_in r.FuseChord_in]);
            set(pvBoom,'XData',[0 0],'YData',r.FuseChord_in+[0 r.BoomLength_in]);
            set(pvTail,'XData',r.FuseWidth_in/2*[-1 1 1 -1], ...
                'YData',r.FuseChord_in+r.BoomLength_in+[0 0 r.TailChord_in r.TailChord_in]);
            set(pvCG,'XData',0,'YData',r.MassCG_in);
            set(pvLift,'XData',0,'YData',r.LiftCenter_in);
            drawnow nocallbacks;
        end
        function refreshPage()
            first=1+pageSize*floor((selected-1)/pageSize);
            if first~=pageStart || isempty(results)
                pageStart=first;
                last=min(first+pageSize-1,height(results));
                tab.Data=results(first:last,:);
                tab.RowName=arrayfun(@num2str,first:last,'UniformOutput',false);
            end

        end
        function clearPreview()
            for h=[pvWing pvFuse pvBoom pvTail pvCG pvLift]
                set(h,'XData',NaN,'YData',NaN);
            end
            counter.Text='No matching geometries.';
        end
        function period=framePeriod()
            % MATLAB timers use millisecond timing resolution.
            period=max(0.001,round(1000/fpsInput.Value)/1000);
        end
        function updateCounter()
            if isempty(results), return; end
            r=results(selected,:);
            counter.Text=sprintf('Match %d / %d | CG error %.4f in | TE gap %.2f in | Target %g fps', ...
                selected,height(results),r.CG_Error_in,r.TE_Separation_in,fpsInput.Value);
        end
        function changeFPS(~,~)
            wasPlaying=strcmp(player.Running,'on');
            % Period changes require a stopped timer; keep the current match.
            pausePlayback();
            player.Period=framePeriod(); player.StartDelay=player.Period;
            updateCounter();
            if wasPlaying && ~isempty(results) && selected<height(results)
                playBtn.Text='Pause'; start(player);
            end
        end
        function pausePlayback()
            if isvalid(player) && strcmp(player.Running,'on'), stop(player); end
            if isvalid(playBtn), playBtn.Text='Play'; end
        end
        function togglePlayback(~,~)
            if isempty(results), return; end
            if strcmp(player.Running,'on'), pausePlayback(); return; end
            if selected>=height(results), selected=1; end
            applyMatch([],[]);
            if selected<height(results)
                playBtn.Text='Pause'; player.Period=framePeriod(); player.StartDelay=player.Period; start(player);
            end
        end
        function advanceFrame(~,~)
            if ~isvalid(dlg) || ~isvalid(fig), stop(player); return; end
            if selected>=height(results), pausePlayback(); return; end
            selected=selected+1; applyMatch([],[]);
            if selected==height(results), pausePlayback(); end
        end
        function stepMatch(delta)
            pausePlayback(); if isempty(results), return; end
            selected=min(height(results),max(1,selected+delta)); applyMatch([],[]);
        end
        function jumpMatch(~,~)
            pausePlayback(); if isempty(results), return; end
            selected=min(height(results),max(1,round(jump.Value))); applyMatch([],[]);
        end
        function playbackError(~,~)
            pausePlayback();
            if isvalid(counter), counter.Text='Playback stopped because of a rendering error.'; end
        end
        function disposePlayback(~,~)
            if isvalid(player), stop(player); delete(player); end
        end
        function exportMatches(~,~)
            pausePlayback();
            if isempty(results), uialert(dlg,'Run a search with matches first.','No results'); return; end
            [file,path]=uiputfile('*.csv','Export every matching geometry','aero_matches.csv');
            if isequal(file,0), return; end
            writetable(results,fullfile(path,file));
        end
    end

end
function T=solveGrid(g,w,p,offsetBounds,tol,requireOverlap)
% CG error = slope * wing_LE_offset + intercept, solved without offset sampling.
% One row represents a continuum of valid offsets at one geometry grid point.
b=95; W=sum(w.*[2 1 1 1]);
assert(W>0 && W<=20 && all(isfinite(w)) && all(w>=0),'Invalid component weights.');
n=prod(cellfun(@numel,g)); data=zeros(n,14); count=0;
for fw=g{1}
 for fc=g{2}
  for cube=g{3}
   if fw<=0 || fw>40 || cube<=0 || cube>7, continue; end
   area=144*(16*W/cube)^(2/3);
   wc=(area-fw*fc)/(b-fw);
   if ~isfinite(wc) || wc<=0 || wc>fc, continue; end
   aw=wc*(b-fw); af=fc*fw;
   slope=2*w(1)/W-aw/area;
   aero0=(af*0.225*fc+aw*0.225*wc)/area;
   for bl=g{4}
    for tc=g{5}
     % Hard trailing-edge constraint, independent of optional overlap checkbox:
     % abs(offset + wc - fc) <= 7  =>  fc - wc - 7 <= offset <= fc - wc + 7.
     lo=max(offsetBounds(1),fc-wc-7);
     hi=min(offsetBounds(2),fc-wc+7);
     if requireOverlap
         % 1e-9 in clearance excludes zero-overlap wing/fuselage contact.
         lo=max(lo,-wc+1e-9);
         hi=min([hi,fc-1e-9,fc+bl-wc]);
     end
     if lo>hi, continue; end
     mass0=(w(2)*p(2)*fc+2*w(1)*p(1)*wc+w(3)*(fc+bl/2)+w(4)*(fc+bl+p(3)*tc))/W;
     intercept=mass0-aero0;
     if slope==0
         if abs(intercept)>tol, continue; end
         best=(lo+hi)/2;
     else
         bounds=sort([(-tol-intercept)/slope,(tol-intercept)/slope]);
         lo=max(lo,bounds(1)); hi=min(hi,bounds(2));
         if lo>hi, continue; end
         best=min(hi,max(lo,-intercept/slope));
     end
     mass=mass0+2*w(1)/W*best; aero=aero0+aw/area*best;
     count=count+1;
     data(count,:)=[b fw fc cube wc bl tc lo hi best mass aero mass-aero W];
    end
   end
  end
 end
end
T=array2table(data(1:count,:),'VariableNames', ...
 {'Span_in','FuseWidth_in','FuseChord_in','CubeLoad','WingChord_in', ...
 'BoomLength_in','TailChord_in','LE_Min_in','LE_Max_in','LE_Best_in', ...
 'MassCG_in','LiftCenter_in','CG_Error_in','GrossWeight_lb'});
% Signed gap is positive when wing TE is aft of fuse TE.
T.WingTE_in=T.LE_Best_in+T.WingChord_in;
T.FuseTE_in=T.FuseChord_in;
T.TE_Separation_in=abs(T.WingTE_in-T.FuseTE_in);
% Include fixed mass assumptions in every exported row for reproducibility.
T.WingSideWeight_lb=repmat(w(1),count,1); T.FuseWeight_lb=repmat(w(2),count,1);
T.BoomWeight_lb=repmat(w(3),count,1); T.TailWeight_lb=repmat(w(4),count,1);
T.WingCG_fraction=repmat(p(1),count,1); T.FuseCG_fraction=repmat(p(2),count,1);
T.TailCG_fraction=repmat(p(3),count,1);
end
