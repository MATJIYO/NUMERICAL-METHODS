classdef matlabREGIS < matlab.apps.AppBase

    properties (Access = public)
        UIFigure        matlab.ui.Figure
        TabGroup        matlab.ui.container.TabGroup

        RootTab         matlab.ui.container.Tab
        MatrixTab       matlab.ui.container.Tab

        % Root Finding UI
        FunctionEdit    matlab.ui.control.EditField
        MethodDrop      matlab.ui.control.DropDown
        CompareCheck    matlab.ui.control.CheckBox

        aField          matlab.ui.control.NumericEditField
        bField          matlab.ui.control.NumericEditField
        x0Field         matlab.ui.control.NumericEditField
        x1Field         matlab.ui.control.NumericEditField
        TolField        matlab.ui.control.NumericEditField
        IterField       matlab.ui.control.NumericEditField

        ComputeBtn      matlab.ui.control.Button
        UITable         matlab.ui.control.Table
        UIAxes          matlab.ui.control.UIAxes
        ErrorAxes       matlab.ui.control.UIAxes
        StepText        matlab.ui.control.TextArea
        FormulaText     matlab.ui.control.TextArea

        % Matrix UI
        MatrixA         matlab.ui.control.EditField
        MatrixB         matlab.ui.control.EditField
        MatrixPower     matlab.ui.control.NumericEditField
        MatrixOp        matlab.ui.control.DropDown
        MatrixBtn       matlab.ui.control.Button
        MatrixResult    matlab.ui.control.TextArea
        MatrixSteps     matlab.ui.control.TextArea

    end

    methods (Access = private)

        %% ── FORMULA DISPLAY ───────────────────────────────────────────────
        function txt = getFormula(~, method)
            switch method
                case 'Bisection'
                    txt = "BISECTION METHOD (Bracketing)" + newline + ...
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━" + newline + ...
                          "Prerequisite: f(xL)·f(xU) < 0" + newline + newline + ...
                          "Root estimate:" + newline + ...
                          "  xR = (xL + xU) / 2" + newline + newline + ...
                          "Approximate Relative Error:" + newline + ...
                          "  |εa| = |(xR_new - xR_old) / xR_new| × 100%" + newline + newline + ...
                          "Update rule:" + newline + ...
                          "  If f(xL)·f(xR) < 0 → xU = xR (1st subinterval)" + newline + ...
                          "  If f(xL)·f(xR) > 0 → xL = xR (2nd subinterval)" + newline + ...
                          "  If f(xL)·f(xR) = 0 → root is xR, stop" + newline + newline + ...
                          "Stop when: |εa| ≤ εs = 0.5×10^(2-n) %";

                case 'Regula Falsi'
                    txt = "REGULA FALSI / FALSE POSITION METHOD (Bracketing)" + newline + ...
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" + newline + ...
                          "Prerequisite: f(xL)·f(xU) < 0" + newline + newline + ...
                          "Root estimate (similar triangles formula):" + newline + ...
                          "  xR = [xU·f(xL) - xL·f(xU)] / [f(xL) - f(xU)]" + newline + newline + ...
                          "Approximate Relative Error:" + newline + ...
                          "  |εa| = |(xR_new - xR_old) / xR_new| × 100%" + newline + newline + ...
                          "Update rule:" + newline + ...
                          "  If f(xL)·f(xR) < 0 → xU = xR" + newline + ...
                          "  If f(xL)·f(xR) > 0 → xL = xR" + newline + ...
                          "  If f(xL)·f(xR) = 0 → root is xR, stop" + newline + newline + ...
                          "Stop when: |εa| < εs";

                case 'Newton-Raphson'
                    txt = "NEWTON-RAPHSON METHOD (Open Method)" + newline + ...
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" + newline + ...
                          "Requires: single initial guess x0, f'(x) ≠ 0" + newline + newline + ...
                          "Iterative formula:" + newline + ...
                          "  x(i+1) = x(i) - f(x(i)) / f'(x(i))" + newline + newline + ...
                          "Derivation from tangent line slope:" + newline + ...
                          "  f'(xi) = [f(xi) - 0] / [xi - x(i+1)]" + newline + ...
                          "  → x(i+1) = xi - f(xi)/f'(xi)" + newline + newline + ...
                          "Approximate Relative Error:" + newline + ...
                          "  |εa| = |(x_new - x_old) / x_new| × 100%" + newline + newline + ...
                          "Advantages: Quadratic convergence (fast)" + newline + ...
                          "Drawbacks: Division by zero if f'(xi)=0," + newline + ...
                          "  diverges near inflection points, root jumping";

                case 'Secant'
                    txt = "SECANT METHOD (Open Method)" + newline + ...
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━" + newline + ...
                          "Requires: two initial guesses x0 and x1" + newline + ...
                          "(does NOT require computing f'(x))" + newline + newline + ...
                          "Iterative formula:" + newline + ...
                          "  x(i+1) = x(i) - f(x(i))·[x(i) - x(i-1)]" + newline + ...
                          "            / [f(x(i)) - f(x(i-1))]" + newline + newline + ...
                          "Approximate Relative Error:" + newline + ...
                          "  |εa| = |(x_new - x_old) / x_new| × 100%" + newline + newline + ...
                          "Stop when: |εa| < εs";

                case 'Simple Fixed-Point'
                    txt = "SIMPLE FIXED-POINT ITERATION (Open Method)" + newline + ...
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" + newline + ...
                          "Rearrange f(x)=0 into the form  x = g(x)" + newline + newline + ...
                          "Iterative formula:" + newline + ...
                          "  x(i+1) = g(x(i))" + newline + newline + ...
                          "Approximate Relative Error:" + newline + ...
                          "  |εa| = |(x(i+1) - x(i)) / x(i+1)| × 100%" + newline + newline + ...
                          "Convergence condition: |g'(x)| < 1" + newline + ...
                          "Convergence type: Linear (slower than Newton-Raphson)" + newline + newline + ...
                          "Note: Enter g(x) in the f(x) field. x0 is initial guess.";

                case 'Incremental'
                    txt = "INCREMENTAL SEARCH METHOD (Bracketing)" + newline + ...
                          "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" + newline + ...
                          "Steps through [a,b] with step Δx" + newline + newline + ...
                          "Sign change condition:" + newline + ...
                          "  f(xL)·f(xU) < 0  →  root in [xL, xU]" + newline + newline + ...
                          "Algorithm:" + newline + ...
                          "  1. Select xL and Δx; compute xU = xL + Δx" + newline + ...
                          "  2. If f(xL)·f(xU) < 0, root is bracketed" + newline + ...
                          "  3. Revert to last xL, reduce Δx (refine)" + newline + ...
                          "  4. Repeat until |εa| ≤ εs" + newline + newline + ...
                          "Root ≈ (xL + xU) / 2 after sufficient refinement";
                otherwise
                    txt = "";
            end
        end

        %% ── ENABLE / DISABLE ROOT INPUTS BASED ON METHOD ─────────────────
        function updateInputs(app)
            method = app.MethodDrop.Value;

            app.aField.Enable  = 'on';
            app.bField.Enable  = 'on';
            app.x0Field.Enable = 'on';
            app.x1Field.Enable = 'on';

            switch method
                case {'Incremental','Bisection','Regula Falsi'}
                    app.x0Field.Enable = 'off';
                    app.x1Field.Enable = 'off';

                case 'Newton-Raphson'
                    app.aField.Enable  = 'off';
                    app.bField.Enable  = 'off';
                    app.x1Field.Enable = 'off';

                case {'Secant'}
                    app.aField.Enable = 'off';
                    app.bField.Enable = 'off';

                case 'Simple Fixed-Point'
                    app.aField.Enable  = 'off';
                    app.bField.Enable  = 'off';
                    app.x1Field.Enable = 'off';
            end

            app.FormulaText.Value = app.getFormula(method);
        end

        %% ── ENABLE / DISABLE MATRIX INPUTS BASED ON OPERATION ────────────
        function updateMatrixInputs(app)
            op = app.MatrixOp.Value;

            app.MatrixB.Enable     = 'on';
            app.MatrixPower.Enable = 'off';

            switch op
                case {'Transpose','Inverse','Determinant','Adjoint','Rank','Eigenvalues'}
                    app.MatrixB.Enable = 'off';

                case 'Power'
                    app.MatrixB.Enable     = 'off';
                    app.MatrixPower.Enable = 'on';
            end
        end

        %% ── FUNCTION STRING FIXER ─────────────────────────────────────────
        function expr = fixFunctionInput(~, str)
            str = strrep(str, ' ', '');
            str = regexprep(str, 'ln\(([^)]+)\)', 'log($1)');
            str = regexprep(str, 'e\^([a-zA-Z0-9]+)', 'exp($1)');
            funcs = {'sin','cos','tan','log','exp','sqrt'};
            for i = 1:numel(funcs)
                f = funcs{i};
                str = regexprep(str, [f '([a-zA-Z0-9]+)'], [f '($1)']);
            end
            str = regexprep(str, '(\d)([a-zA-Z])', '$1*$2');
            expr = str;
        end

        %% ── ROOT-FINDING METHODS ──────────────────────────────────────────
        function [data, errors, root, steps] = runMethod(~, method, fh, f, a, b, x0, x1, tol, maxIter)

            data   = [];
            errors = [];
            root   = NaN;
            steps  = "";

            switch method

                % ── Bisection ──────────────────────────────────────────────
                case 'Bisection'
                    if fh(a)*fh(b) > 0
                        error('f(a) and f(b) must have opposite signs for Bisection.');
                    end

                    steps = steps + sprintf("Bisection Method\n");
                    steps = steps + sprintf("f(x) evaluated: f(%.4f)=%.6f, f(%.4f)=%.6f\n", a, fh(a), b, fh(b));
                    steps = steps + sprintf("f(xL)·f(xU) = %.6f < 0  (sign change confirmed)\n\n", fh(a)*fh(b));

                    xr_old = NaN;
                    for i = 1:maxIter
                        xr  = (a + b) / 2;
                        fxr = fh(xr);
                        fxa = fh(a);

                        if i == 1
                            ea = NaN;
                            ea_disp = "---";
                        else
                            ea = abs((xr - xr_old) / xr) * 100;
                            ea_disp = sprintf("%.6f%%", ea);
                        end

                        if fxa * fxr < 0
                            subint = "1st (xU = xR)";
                            b = xr;
                        elseif fxa * fxr > 0
                            subint = "2nd (xL = xR)";
                            a = xr;
                        else
                            subint = "exact root";
                        end

                        data(i,:) = [i, a, b, xr, fxr, double(~isnan(ea))*ea];
                        if isnan(ea), errors(i) = 0; else, errors(i) = ea; end

                        steps = steps + sprintf("Iteration %d:\n", i);
                        steps = steps + sprintf("  xL = %.6f,  xU = %.6f\n", a, b);
                        steps = steps + sprintf("  xR = (xL + xU)/2 = (%.6f + %.6f)/2 = %.6f\n", a, b, xr);
                        steps = steps + sprintf("  f(xR) = %.6f\n", fxr);
                        steps = steps + sprintf("  |ea| = %s\n", ea_disp);
                        steps = steps + sprintf("  f(xL)*f(xR) -> Subinterval: %s\n", subint);
                        steps = steps + "  ---------------------------------\n";

                        if ~isnan(ea) && ea < tol*100
                            root = xr;
                            steps = steps + sprintf("\nConverged! Root = %.8f  (|ea|=%.6f%% < es=%.4f%%)\n", root, ea, tol*100);
                            break;
                        end
                        xr_old = xr;
                    end
                    if isnan(root), root = (a+b)/2; end

                % ── Regula Falsi ───────────────────────────────────────────
                case 'Regula Falsi'
                    if fh(a)*fh(b) > 0
                        error('f(a) and f(b) must have opposite signs for Regula Falsi.');
                    end

                    steps = steps + sprintf("Regula Falsi (False Position) Method\n");
                    steps = steps + sprintf("f(xL)*f(xU) = %.6f < 0\n\n", fh(a)*fh(b));

                    xr_old = NaN;
                    for i = 1:maxIter
                        fxl = fh(a);
                        fxu = fh(b);
                        xr  = (b*fxl - a*fxu) / (fxl - fxu);
                        fxr = fh(xr);

                        if i == 1
                            ea = NaN;
                            ea_disp = "---";
                        else
                            ea = abs((xr - xr_old) / xr) * 100;
                            ea_disp = sprintf("%.6f%%", ea);
                        end

                        if fxl * fxr < 0
                            signTxt = "< 0 -> xU = xR";
                            b = xr;
                        elseif fxl * fxr > 0
                            signTxt = "> 0 -> xL = xR";
                            a = xr;
                        else
                            signTxt = "= 0 -> exact root";
                        end

                        data(i,:) = [i, a, b, xr, double(~isnan(ea))*ea, fxl, fxu, fxr];
                        if isnan(ea), errors(i) = 0; else, errors(i) = ea; end

                        steps = steps + sprintf("Iteration %d:\n", i);
                        steps = steps + sprintf("  xL = %.6f,  xU = %.6f\n", a, b);
                        steps = steps + sprintf("  xR = [xU*f(xL) - xL*f(xU)] / [f(xL) - f(xU)]\n");
                        steps = steps + sprintf("     = [%.4f*%.6f - %.4f*%.6f] / [%.6f - %.6f]\n", b, fxl, a, fxu, fxl, fxu);
                        steps = steps + sprintf("     = %.6f\n", xr);
                        steps = steps + sprintf("  f(xL)=%.6f  f(xU)=%.6f  f(xR)=%.6f\n", fxl, fxu, fxr);
                        steps = steps + sprintf("  f(xL)*f(xR) %s\n", signTxt);
                        steps = steps + sprintf("  |ea| = %s\n", ea_disp);
                        steps = steps + "  ---------------------------------\n";

                        if ~isnan(ea) && ea < tol*100
                            root = xr;
                            steps = steps + sprintf("\nConverged! Root = %.8f  (|ea|=%.6f%% < es=%.4f%%)\n", root, ea, tol*100);
                            break;
                        end
                        xr_old = xr;
                    end

                % ── Newton-Raphson ─────────────────────────────────────────
                case 'Newton-Raphson'
                    syms xs
                    df = matlabFunction(diff(f, xs));

                    steps = steps + sprintf("Newton-Raphson Method\n");
                    steps = steps + sprintf("f(x) and f'(x) computed symbolically.\n");
                    steps = steps + sprintf("Initial guess: x0 = %.6f\n\n", x0);

                    for i = 1:maxIter
                        fx0  = fh(x0);
                        dfx0 = df(x0);

                        if abs(dfx0) < 1e-12
                            error('Zero derivative at x=%.6f -- method fails (division by zero).', x0);
                        end

                        x_new = x0 - fx0 / dfx0;
                        ea    = abs((x_new - x0) / x_new) * 100;
                        fx_new = fh(x_new);

                        data(i,:) = [i, x_new, fx_new, ea];
                        errors(i)  = ea;

                        steps = steps + sprintf("Iteration %d:\n", i);
                        steps = steps + sprintf("  xi = %.6f\n", x0);
                        steps = steps + sprintf("  f(xi)  = %.6f\n", fx0);
                        steps = steps + sprintf("  f'(xi) = %.6f\n", dfx0);
                        steps = steps + sprintf("  x(i+1) = xi - f(xi)/f'(xi)\n");
                        steps = steps + sprintf("         = %.6f - %.6f/%.6f\n", x0, fx0, dfx0);
                        steps = steps + sprintf("         = %.8f\n", x_new);
                        steps = steps + sprintf("  |ea| = |%.6f - %.6f| / %.6f * 100%% = %.6f%%\n", x_new, x0, x_new, ea);
                        steps = steps + "  ---------------------------------\n";

                        if ea < tol*100
                            root = x_new;
                            steps = steps + sprintf("\nConverged! Root = %.8f  (|ea|=%.6f%% < es=%.4f%%)\n", root, ea, tol*100);
                            break;
                        end
                        x0 = x_new;
                    end

                % ── Secant ─────────────────────────────────────────────────
                case 'Secant'
                    steps = steps + sprintf("Secant Method\n");
                    steps = steps + sprintf("Initial guesses: x0 = %.6f,  x1 = %.6f\n\n", x0, x1);

                    for i = 1:maxIter
                        fx0 = fh(x0);
                        fx1 = fh(x1);
                        denom = fx1 - fx0;

                        if abs(denom) < 1e-12
                            error('Division by zero in Secant method at iteration %d (f(x1)-f(x0)~0).', i);
                        end

                        x2 = x1 - fx1 * (x1 - x0) / denom;
                        fx2 = fh(x2);

                        if abs(x2) < 1e-12
                            ea = abs(x2 - x1) * 100;
                        else
                            ea = abs((x2 - x1) / x2) * 100;
                        end

                        data(i,:) = [i, x0, x1, x2, ea, fx0, fx1, fx2];
                        errors(i)  = ea;

                        steps = steps + sprintf("Iteration %d:\n", i);
                        steps = steps + sprintf("  x(i-1) = %.6f,  x(i) = %.6f\n", x0, x1);
                        steps = steps + sprintf("  f(x(i-1)) = %.6f,  f(x(i)) = %.6f\n", fx0, fx1);
                        steps = steps + sprintf("  x(i+1) = x(i) - f(x(i))*[x(i) - x(i-1)] / [f(x(i)) - f(x(i-1))]\n");
                        steps = steps + sprintf("         = %.6f - %.6f*(%.6f-%.6f)/(%.6f-%.6f)\n", x1, fx1, x1, x0, fx1, fx0);
                        steps = steps + sprintf("         = %.8f\n", x2);
                        steps = steps + sprintf("  f(x(i+1)) = %.6f\n", fx2);
                        steps = steps + sprintf("  |ea| = %.6f%%\n", ea);
                        steps = steps + "  ---------------------------------\n";

                        if ea < tol*100
                            root = x2;
                            steps = steps + sprintf("\nConverged! Root = %.8f  (|ea|=%.6f%% < es=%.4f%%)\n", root, ea, tol*100);
                            break;
                        end

                        x0 = x1;
                        x1 = x2;
                    end

                % ── Simple Fixed-Point Iteration ───────────────────────────
                case 'Simple Fixed-Point'
                    steps = steps + sprintf("Simple Fixed-Point Iteration\n");
                    steps = steps + sprintf("g(x) = f(x) as entered (rearranged so x = g(x))\n");
                    steps = steps + sprintf("Initial guess: x0 = %.6f\n\n", x0);

                    for i = 1:maxIter
                        x_new = fh(x0);
                        if abs(x_new) < 1e-12
                            ea = abs(x_new - x0)*100;
                        else
                            ea = abs((x_new - x0) / x_new) * 100;
                        end

                        data(i,:) = [i, x0, x_new, ea];
                        errors(i)  = ea;

                        steps = steps + sprintf("Iteration %d:\n", i);
                        steps = steps + sprintf("  x(i) = %.6f\n", x0);
                        steps = steps + sprintf("  x(i+1) = g(x(i)) = %.8f\n", x_new);
                        steps = steps + sprintf("  |ea| = |(%.6f - %.6f)/%.6f| * 100%% = %.6f%%\n", x_new, x0, x_new, ea);
                        steps = steps + "  ---------------------------------\n";

                        if ea < tol*100
                            root = x_new;
                            steps = steps + sprintf("\nConverged! Root = %.8f  (|ea|=%.6f%% < es=%.4f%%)\n", root, ea, tol*100);
                            break;
                        end
                        x0 = x_new;
                    end

                % ── Incremental Search ─────────────────────────────────────
                case 'Incremental'
                    h             = (b - a) / 20;
                    xl            = a;
                    xu            = xl + h;
                    refineFactor  = 10;
                    maxRefine     = 5;
                    refineLevel   = 0;

                    steps = steps + sprintf("Incremental Search Method\n");
                    steps = steps + sprintf("Interval [%.4f, %.4f], initial step Dx = %.6f\n\n", a, b, h);

                    for i = 1:maxIter
                        if xu > b, break; end

                        fxl = fh(xl);
                        fxu = fh(xu);

                        data(i,:) = [i, xl, h, xu, fxl, fxu];
                        errors(i)  = abs(fxu - fxl);

                        steps = steps + sprintf("Iteration %d:\n", i);
                        steps = steps + sprintf("  xL = %.6f,  Dx = %.8f,  xU = %.6f\n", xl, h, xu);
                        steps = steps + sprintf("  f(xL) = %.6f,  f(xU) = %.6f\n", fxl, fxu);
                        steps = steps + sprintf("  f(xL)*f(xU) = %.6f", fxl*fxu);

                        if fxl * fxu < 0
                            steps = steps + " < 0  -> Sign change detected!\n";
                            refineLevel = refineLevel + 1;

                            if refineLevel <= maxRefine
                                h  = h / refineFactor;
                                xu = xl + h;
                                steps = steps + sprintf("  -> Refining: new Dx = %.8f\n", h);
                                steps = steps + "  ---------------------------------\n";
                                continue;
                            else
                                root = (xl + xu) / 2;
                                steps = steps + sprintf("  -> Root = %.8f\n", root);
                                steps = steps + "  ---------------------------------\n";
                                steps = steps + sprintf("\nRoot found = %.8f\n", root);
                                break;
                            end
                        else
                            steps = steps + " >= 0  -> No sign change, advance interval\n";
                        end

                        xl = xu;
                        xu = xl + h;
                        steps = steps + "  ---------------------------------\n";
                    end
            end
        end

        %% ── COMPUTE ROOT (button callback) ────────────────────────────────
        function computeRoot(app)
            try
                syms x

                inputStr = app.FunctionEdit.Value;
                fixedStr = app.fixFunctionInput(inputStr);
                f        = str2sym(fixedStr);
                fh       = matlabFunction(f);

                a       = app.aField.Value;
                b       = app.bField.Value;
                x0      = app.x0Field.Value;
                x1      = app.x1Field.Value;
                tol     = app.TolField.Value;
                maxIter = round(app.IterField.Value);

                if a >= b && ~ismember(app.MethodDrop.Value, {'Newton-Raphson','Secant','Simple Fixed-Point'})
                    error('a must be less than b.');
                end

                if app.CompareCheck.Value
                    methodsList = {'Incremental','Bisection','Regula Falsi','Newton-Raphson','Secant'};
                else
                    methodsList = {app.MethodDrop.Value};
                end

                cla(app.UIAxes);
                cla(app.ErrorAxes);
                hold(app.UIAxes,   'on');
                hold(app.ErrorAxes,'on');

                % Plot function
                if ismember(app.MethodDrop.Value, {'Newton-Raphson','Secant','Simple Fixed-Point'})
                    plotRange = [x0-3, x0+3];
                else
                    plotRange = [a, b];
                end
                fplot(app.UIAxes, fh, plotRange, 'LineWidth', 2, 'DisplayName', 'f(x)', 'Color', [0.2 0.4 0.8]);
                yline(app.UIAxes, 0, '--k', 'DisplayName', 'y=0');

                allSteps = "";

                for m = 1:numel(methodsList)
                    method = methodsList{m};

                    [data, errors, root, steps] = ...
                        app.runMethod(method, fh, f, a, b, x0, x1, tol, maxIter);

                    switch method
                        case 'Regula Falsi'
                            app.UITable.ColumnName = {'Iter','xL','xU','xR','|ea|%','f(xL)','f(xU)','f(xR)'};
                        case 'Secant'
                            app.UITable.ColumnName = {'Iter','x(i-1)','x(i)','x(i+1)','|ea|%','f(xi-1)','f(xi)','f(xi+1)'};
                        case 'Incremental'
                            app.UITable.ColumnName = {'Iter','xL','Dh','xU','f(xL)','f(xU)'};
                        case 'Bisection'
                            app.UITable.ColumnName = {'Iter','xL','xU','xR','f(xR)','|ea|%'};
                        case 'Newton-Raphson'
                            app.UITable.ColumnName = {'Iter','x(i+1)','f(x)','|ea|%'};
                        case 'Simple Fixed-Point'
                            app.UITable.ColumnName = {'Iter','x(i)','x(i+1)','|ea|%'};
                        otherwise
                            app.UITable.ColumnName = {'Iter','x','f(x)','|ea|%'};
                    end

                    app.UITable.Data = data;

                    validErr = errors;
                    validErr(isnan(validErr)) = 0;
                    plot(app.ErrorAxes, validErr, '-o', 'DisplayName', method, 'LineWidth', 1.5);

                    if ~isnan(root)
                        plot(app.UIAxes, root, fh(root), 'o', ...
                            'MarkerSize', 10, 'LineWidth', 2.5, 'DisplayName', [method ' root']);
                    end

                    allSteps = allSteps + "==============================" + newline;
                    allSteps = allSteps + "  " + method + newline;
                    allSteps = allSteps + "==============================" + newline;
                    allSteps = allSteps + steps + newline;
                end

                app.StepText.Value    = allSteps;
                app.FormulaText.Value = app.getFormula(app.MethodDrop.Value);

                legend(app.UIAxes,    'show', 'Location', 'best');
                legend(app.ErrorAxes, 'show', 'Location', 'best');
                grid(app.UIAxes,    'on');
                grid(app.ErrorAxes, 'on');
                title(app.UIAxes,    'Function & Root(s)');
                xlabel(app.UIAxes,   'x');
                ylabel(app.UIAxes,   'f(x)');
                title(app.ErrorAxes, 'Approximate Relative Error per Iteration');
                xlabel(app.ErrorAxes,'Iteration');
                ylabel(app.ErrorAxes,'|ea| (%)');

            catch ME
                uialert(app.UIFigure, ME.message, 'Computation Error');
            end
        end

        %% ── MATRIX OPERATIONS ─────────────────────────────────────────────
        function computeMatrix(app)
            try
                A  = str2num(app.MatrixA.Value); %#ok<ST2NM>
                B  = str2num(app.MatrixB.Value); %#ok<ST2NM>
                op = app.MatrixOp.Value;
                steps = "";

                if isempty(A)
                    error('Matrix A is invalid. Use MATLAB notation, e.g. [1 2; 3 4].');
                end

                [rA, cA] = size(A);

                switch op

                    case 'Addition'
                        if isempty(B), error('Matrix B is required.'); end
                        if ~isequal(size(A), size(B))
                            error('Matrices must have the same size for Addition.');
                        end
                        R = A + B;
                        steps = steps + "MATRIX ADDITION: R = A + B\n";
                        steps = steps + "Add corresponding elements:\n\n";
                        for i = 1:rA
                            for j = 1:cA
                                steps = steps + sprintf("  R(%d,%d) = %.4f + %.4f = %.4f\n", i, j, A(i,j), B(i,j), R(i,j));
                            end
                        end

                    case 'Multiplication'
                        if isempty(B), error('Matrix B is required.'); end
                        if size(A,2) ~= size(B,1)
                            error('Columns of A must equal rows of B.');
                        end
                        R = A * B;
                        [~, cB] = size(B);
                        steps = steps + "MATRIX MULTIPLICATION: R = A x B\n";
                        steps = steps + sprintf("A is %dx%d, B is %dx%d -> R is %dx%d\n\n", rA, cA, cA, cB, rA, cB);
                        steps = steps + "R(i,j) = dot product of row i of A with column j of B:\n\n";
                        for i = 1:rA
                            for j = 1:cB
                                rowStr = "";
                                for k = 1:cA
                                    if k > 1, rowStr = rowStr + " + "; end
                                    rowStr = rowStr + sprintf("%.4f*%.4f", A(i,k), B(k,j));
                                end
                                steps = steps + sprintf("  R(%d,%d) = %s = %.4f\n", i, j, rowStr, R(i,j));
                            end
                        end

                    case 'Inverse'
                        if rA ~= cA, error('Matrix must be square for Inverse.'); end
                        detA = det(A);
                        if abs(detA) < 1e-12, error('Matrix is singular (det = 0). Inverse does not exist.'); end
                        R = inv(A);
                        steps = steps + "MATRIX INVERSE: R = A^-1\n\n";
                        steps = steps + sprintf("Step 1: Check det(A) = %.6f != 0\n\n", detA);
                        steps = steps + "Step 2: Form augmented matrix [A | I] and row-reduce:\n\n";
                        aug = [A, eye(rA)];
                        steps = steps + app.formatMatrix(aug, "  [A | I] =") + newline;
                        steps = steps + "Step 3: Apply RREF -- right half becomes A^-1\n\n";
                        steps = steps + "Result A^-1 =\n";
                        steps = steps + app.formatMatrix(R, "  ");

                    case 'Determinant'
                        if rA ~= cA, error('Matrix must be square for Determinant.'); end
                        R = det(A);
                        steps = steps + "DETERMINANT: det(A)\n\n";
                        if rA == 1
                            steps = steps + sprintf("1x1 matrix: det = %.6f\n", R);
                        elseif rA == 2
                            steps = steps + "For 2x2: det(A) = a11*a22 - a12*a21\n";
                            steps = steps + sprintf("  = %.4f*%.4f - %.4f*%.4f\n", A(1,1), A(2,2), A(1,2), A(2,1));
                            steps = steps + sprintf("  = %.6f - %.6f\n", A(1,1)*A(2,2), A(1,2)*A(2,1));
                            steps = steps + sprintf("  = %.6f\n", R);
                        elseif rA == 3
                            steps = steps + "For 3x3: Sarrus rule / cofactor expansion:\n";
                            steps = steps + "  det = a11(a22*a33 - a23*a32)\n";
                            steps = steps + "       -a12(a21*a33 - a23*a31)\n";
                            steps = steps + "       +a13(a21*a32 - a22*a31)\n\n";
                            steps = steps + sprintf("  det = %.4f(%.4f*%.4f - %.4f*%.4f)\n", A(1,1), A(2,2), A(3,3), A(2,3), A(3,2));
                            steps = steps + sprintf("       -%.4f(%.4f*%.4f - %.4f*%.4f)\n", A(1,2), A(2,1), A(3,3), A(2,3), A(3,1));
                            steps = steps + sprintf("       +%.4f(%.4f*%.4f - %.4f*%.4f)\n", A(1,3), A(2,1), A(3,2), A(2,2), A(3,1));
                            steps = steps + sprintf("\n  det(A) = %.6f\n", R);
                        else
                            steps = steps + "  (LU decomposition used for large matrix)\n";
                            steps = steps + sprintf("  det(A) = %.6f\n", R);
                        end

                    case 'Transpose'
                        R = A';
                        steps = steps + "TRANSPOSE: R = A^T\n\n";
                        steps = steps + sprintf("Rule: R(i,j) = A(j,i)\n");
                        steps = steps + sprintf("A is %dx%d -> A^T is %dx%d\n\n", rA, cA, cA, rA);
                        for i = 1:rA
                            for j = 1:cA
                                steps = steps + sprintf("  R(%d,%d) = A(%d,%d) = %.4f\n", j, i, i, j, A(i,j));
                            end
                        end

                    case 'Power'
                        if rA ~= cA, error('Matrix must be square for Power.'); end
                        n = round(app.MatrixPower.Value);
                        R = A ^ n;
                        steps = steps + sprintf("MATRIX POWER: R = A^%d\n\n", n);
                        steps = steps + sprintf("Computed by repeated multiplication: AxAx...xA (%d times)\n\n", n);
                        steps = steps + "Result:\n";
                        steps = steps + app.formatMatrix(R, "  ");

                    case 'Adjoint'
                        if rA ~= cA, error('Matrix must be square for Adjoint.'); end
                        R = app.adjointMatrix(A);
                        steps = steps + "ADJOINT (Adjugate) MATRIX: adj(A) = C^T\n\n";
                        steps = steps + "Step 1: Compute cofactors C(i,j) = (-1)^(i+j) * M(i,j)\n";
                        steps = steps + "        where M(i,j) is the minor (det of submatrix excluding row i, col j)\n\n";
                        for i = 1:rA
                            for j = 1:cA
                                M = A; M(i,:) = []; M(:,j) = [];
                                minorVal = det(M);
                                cofVal = (-1)^(i+j) * minorVal;
                                steps = steps + sprintf("  C(%d,%d) = (-1)^(%d+%d) * det(M%d%d) = (-1)^%d * %.4f = %.4f\n", ...
                                    i, j, i, j, i, j, i+j, minorVal, cofVal);
                            end
                        end
                        steps = steps + "\nStep 2: Transpose cofactor matrix -> adj(A) = C^T\n\n";
                        steps = steps + "adj(A) =\n";
                        steps = steps + app.formatMatrix(R, "  ");

                    case 'Rank'
                        steps = steps + "MATRIX RANK using RREF\n\n";
                        steps = steps + "The rank = number of non-zero rows in RREF(A)\n\n";
                        steps = steps + "Step 1: Original Matrix A =\n";
                        steps = steps + app.formatMatrix(A, "  ") + newline;
                        steps = steps + "Step 2: Apply Row Reduction (RREF):\n\n";
                        [Rref, pivots] = rref(A);
                        steps = steps + app.rrefSteps(A) + newline;
                        steps = steps + "Step 3: RREF(A) =\n";
                        steps = steps + app.formatMatrix(Rref, "  ") + newline;
                        R = rank(A);
                        nonZeroRows = sum(any(abs(Rref) > 1e-10, 2));
                        steps = steps + sprintf("Step 4: Count non-zero rows = %d\n\n", nonZeroRows);
                        steps = steps + sprintf("Rank(A) = %d\n", R);
                        steps = steps + sprintf("   Pivot columns: %s\n", mat2str(pivots));
                        steps = steps + sprintf("   Nullity = %d - %d = %d\n", cA, R, cA - R);

                    case 'Eigenvalues'
                        if rA ~= cA, error('Matrix must be square for Eigenvalues.'); end
                        [V, D] = eig(A);
                        evals = diag(D);
                        R = evals;
                        steps = steps + "EIGENVALUES & EIGENVECTORS\n\n";
                        steps = steps + "Definition: Av = lv  ->  det(A - lI) = 0\n\n";
                        steps = steps + "Step 1: Solve characteristic polynomial det(A - lI) = 0\n\n";
                        for k = 1:length(evals)
                            steps = steps + sprintf("  l%d = %.6f\n", k, real(evals(k)));
                            if abs(imag(evals(k))) > 1e-10
                                steps = steps + sprintf("       (complex: %.4f + %.4fi)\n", real(evals(k)), imag(evals(k)));
                            end
                            steps = steps + sprintf("  Eigenvector v%d = [", k);
                            for kk = 1:rA
                                if kk < rA
                                    steps = steps + sprintf("%.4f, ", real(V(kk,k)));
                                else
                                    steps = steps + sprintf("%.4f", real(V(kk,k)));
                                end
                            end
                            steps = steps + "]^T\n\n";
                        end

                    case 'Solve AX=B'
                        if isempty(B), error('Matrix B is required for Solve AX=B.'); end
                        if size(A,1) ~= size(B,1)
                            error('Rows of A must equal rows of B.');
                        end
                        detA = det(A);
                        if abs(detA) < 1e-12, error('Matrix A is singular -- no unique solution.'); end
                        R = A \ B;
                        steps = steps + "SOLVE SYSTEM AX = B using RREF\n\n";
                        steps = steps + sprintf("Step 1: Check det(A) = %.6f != 0\n\n", detA);
                        steps = steps + "Step 2: Form augmented matrix [A | B]:\n";
                        aug = [A, B];
                        steps = steps + app.formatMatrix(aug, "  ") + newline;
                        steps = steps + "Step 3: Apply RREF to [A | B]:\n";
                        augRref = rref(aug);
                        steps = steps + app.formatMatrix(augRref, "  ") + newline;
                        steps = steps + "Step 4: Read solution from RREF:\n\n";
                        [rR, cR] = size(R);
                        for i = 1:rR
                            for j = 1:cR
                                steps = steps + sprintf("  x(%d,%d) = %.6f\n", i, j, R(i,j));
                            end
                        end
                end

                if isscalar(R)
                    app.MatrixResult.Value = {num2str(R, 10)};
                elseif isvector(R)
                    lines = {};
                    for k = 1:length(R)
                        if isreal(R(k))
                            lines{end+1} = sprintf("  l%d = %.6f", k, R(k));
                        else
                            lines{end+1} = sprintf("  l%d = %.4f + %.4fi", k, real(R(k)), imag(R(k)));
                        end
                    end
                    app.MatrixResult.Value = lines;
                else
                    lines = {};
                    for i = 1:size(R,1)
                        row = "";
                        for j = 1:size(R,2)
                            row = row + sprintf("  %10.5f", R(i,j));
                        end
                        lines{end+1} = char(row);
                    end
                    app.MatrixResult.Value = lines;
                end

                app.MatrixSteps.Value = steps;

            catch ME
                app.MatrixResult.Value = {"Error: " + ME.message};
                app.MatrixSteps.Value  = "Error: " + ME.message;
            end
        end

        %% ── FORMAT MATRIX FOR DISPLAY ─────────────────────────────────────
        function s = formatMatrix(~, M, prefix)
            s = "";
            [r, c] = size(M);
            for i = 1:r
                row = prefix;
                row = row + "[ ";
                for j = 1:c
                    row = row + sprintf("%10.4f ", M(i,j));
                end
                row = row + "]\n";
                s = s + row;
            end
        end

        %% ── RREF STEP-BY-STEP ─────────────────────────────────────────────
        function s = rrefSteps(app, A)
            s = "";
            M = double(A);
            [r, c] = size(M);
            pivRow = 0;

            for col = 1:c
                if pivRow >= r, break; end

                maxVal = 0; maxRow = 0;
                for row = pivRow+1:r
                    if abs(M(row,col)) > maxVal
                        maxVal = abs(M(row,col));
                        maxRow = row;
                    end
                end

                if maxVal < 1e-10
                    s = s + sprintf("  Column %d: no pivot (skip)\n", col);
                    continue;
                end

                pivRow = pivRow + 1;

                if maxRow ~= pivRow
                    M([pivRow, maxRow], :) = M([maxRow, pivRow], :);
                    s = s + sprintf("  R%d <-> R%d\n", pivRow, maxRow);
                    s = s + app.formatMatrix(M, "    ");
                end

                if abs(M(pivRow, col)) > 1e-10
                    scale = M(pivRow, col);
                    M(pivRow, :) = M(pivRow, :) / scale;
                    s = s + sprintf("  R%d / %.4f\n", pivRow, scale);
                    s = s + app.formatMatrix(M, "    ");
                end

                for row = 1:r
                    if row ~= pivRow && abs(M(row, col)) > 1e-10
                        factor = M(row, col);
                        M(row, :) = M(row, :) - factor * M(pivRow, :);
                        s = s + sprintf("  R%d = R%d - (%.4f)*R%d\n", row, row, factor, pivRow);
                        s = s + app.formatMatrix(M, "    ");
                    end
                end
            end
        end

        %% ── ADJOINT ──────────────────────────────────────────────────────
        function Adj = adjointMatrix(~, A)
            n = size(A, 1);
            if n ~= size(A, 2), error('Matrix must be square.'); end
            if n == 1, Adj = 1; return; end
            C = zeros(n);
            for i = 1:n
                for j = 1:n
                    M = A; M(i,:) = []; M(:,j) = [];
                    C(i,j) = (-1)^(i+j) * det(M);
                end
            end
            Adj = C';
        end

    end % private methods

    %% ── CONSTRUCTOR ───────────────────────────────────────────────────────
    methods (Access = public)

        function app = matlabREGIS

            %% Figure
            app.UIFigure = uifigure( ...
                'Position', [50 50 1300 780], ...
                'Name',     'Numerical Methods & Linear Algebra App');
            registerApp(app, app.UIFigure);          % <-- REQUIRED FIX
            app.UIFigure.Color = [1 1 1];

            app.TabGroup = uitabgroup(app.UIFigure, 'Position', [0 0 1300 780]);

            %% ══════════════════════════════════════════════════════════════
            %%  TAB 1 — ROOT FINDING
            %% ══════════════════════════════════════════════════════════════
            app.RootTab = uitab(app.TabGroup, 'Title', 'Root Finding');

            mainGrid = uigridlayout(app.RootTab, [4 2]);
            mainGrid.RowHeight    = {165, '1x', '1x', '1x'};
            mainGrid.ColumnWidth  = {'1x', '1x'};
            mainGrid.Padding      = [10 10 10 10];

            % ── Input Panel ──────────────────────────────────────────────
            inputPanel = uipanel(mainGrid, 'Title', 'Inputs', 'FontWeight', 'bold', 'FontSize', 12);
            inputPanel.BackgroundColor = [1 1 1];
            inputPanel.Layout.Row    = 1;
            inputPanel.Layout.Column = [1 2];

            inputGrid = uigridlayout(inputPanel, [3 8]);
            inputGrid.RowHeight   = {'1x','1x','1x'};
            inputGrid.ColumnWidth = repmat({'1x'}, 1, 8);

            lbl = @(g,t) uilabel(g, 'Text', t, 'FontWeight', 'bold');
            lbl(inputGrid, 'f(x)  or  g(x)');
            lbl(inputGrid, 'Method');
            lbl(inputGrid, 'Compare All');
            lbl(inputGrid, 'a  (xL)');
            lbl(inputGrid, 'b  (xU)');
            lbl(inputGrid, 'x0');
            lbl(inputGrid, 'x1');
            uilabel(inputGrid, 'Text', '');

            app.FunctionEdit = uieditfield(inputGrid, 'text', 'Value', 'x^3-x-1', 'FontSize', 13);

            app.MethodDrop = uidropdown(inputGrid, ...
                'Items', {'Incremental','Bisection','Regula Falsi','Newton-Raphson','Secant','Simple Fixed-Point'}, ...
                'ValueChangedFcn', @(~,~) app.updateInputs(), 'FontSize', 12);

            app.CompareCheck = uicheckbox(inputGrid, 'Text', '');

            app.aField  = uieditfield(inputGrid, 'numeric', 'Value', 1);
            app.bField  = uieditfield(inputGrid, 'numeric', 'Value', 2);
            app.x0Field = uieditfield(inputGrid, 'numeric', 'Value', 1);
            app.x1Field = uieditfield(inputGrid, 'numeric', 'Value', 2);
            uilabel(inputGrid, 'Text', '');

            lbl(inputGrid, 'Tolerance');
            app.TolField  = uieditfield(inputGrid, 'numeric', 'Value', 1e-5);
            lbl(inputGrid, 'Max Iterations');
            app.IterField = uieditfield(inputGrid, 'numeric', 'Value', 50);
            app.ComputeBtn = uibutton(inputGrid, ...
                'Text', 'Compute Root', ...
                'FontWeight', 'bold', ...
                'FontSize', 13, ...
                'BackgroundColor', [0.95 0.95 0.95], ...
                'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(~,~) app.computeRoot());
            uilabel(inputGrid, 'Text', '');
            uilabel(inputGrid, 'Text', '');
            uilabel(inputGrid, 'Text', '');

            % Table
            app.UITable = uitable(mainGrid);
            app.UITable.BackgroundColor = [1 1 1];
            app.UITable.Layout.Row    = 2;
            app.UITable.Layout.Column = [1 2];
            app.UITable.FontSize = 11;

            % Axes
            app.UIAxes = uiaxes(mainGrid);
            app.UIAxes.Layout.Row    = 3;
            app.UIAxes.Layout.Column = 1;

            app.ErrorAxes = uiaxes(mainGrid);
            app.ErrorAxes.Layout.Row    = 3;
            app.ErrorAxes.Layout.Column = 2;

            % Step-by-step text
            stepPanel = uipanel(mainGrid, 'Title', 'Step-by-Step Solution', 'FontWeight', 'bold');
            inputPanel.BackgroundColor = [1 1 1];
            stepPanel.Layout.Row    = 4;
            stepPanel.Layout.Column = 1;
            stepGrid = uigridlayout(stepPanel, [1 1]);
            stepGrid.Padding = [4 4 4 4];
            app.StepText = uitextarea(stepGrid, 'FontSize', 11, 'FontName', 'Courier New');
            app.StepText.Editable = 'off';
            app.StepText.Layout.Row = 1; app.StepText.Layout.Column = 1;

            % Formula panel
            fmlPanel = uipanel(mainGrid, 'Title', 'Method Formula & Description', 'FontWeight', 'bold');
            inputPanel.BackgroundColor = [1 1 1];
            fmlPanel.Layout.Row    = 4;
            fmlPanel.Layout.Column = 2;
            fmlGrid = uigridlayout(fmlPanel, [1 1]);
            fmlGrid.Padding = [4 4 4 4];
            app.FormulaText = uitextarea(fmlGrid, 'FontSize', 11, 'FontName', 'Courier New');
            app.FormulaText.Editable = 'off';
            app.FormulaText.Layout.Row = 1; app.FormulaText.Layout.Column = 1;

            %% ══════════════════════════════════════════════════════════════
            %%  TAB 2 — LINEAR ALGEBRA (MATRIX OPERATIONS)
            %% ══════════════════════════════════════════════════════════════
            app.MatrixTab = uitab(app.TabGroup, 'Title', 'Linear Algebra');

            mainME = uigridlayout(app.MatrixTab, [1 3]);
            mainME.ColumnWidth   = {320, '1x', '1x'};
            mainME.Padding       = [15 15 15 15];
            mainME.ColumnSpacing = 15;

            % ── LEFT: input controls ─────────────────────────────────────
            ctrlPanel = uipanel(mainME, 'Title', 'Inputs', 'FontWeight', 'bold', 'FontSize', 12);
            inputPanel.BackgroundColor = [1 1 1];
            ctrlPanel.Layout.Column = 1;

            gridM = uigridlayout(ctrlPanel, [12 2]);
            gridM.RowHeight   = {20, 34, 20, 34, 20, 34, 20, 34, 8, 20, 20, 44};
            gridM.ColumnWidth = {100, '1x'};
            gridM.Padding     = [14 14 14 14];
            gridM.RowSpacing  = 4;

            lA = uilabel(gridM, 'Text', 'Matrix A', 'FontWeight', 'bold', 'FontSize', 12);
            lA.Layout.Row = 1; lA.Layout.Column = [1 2];
            app.MatrixA = uieditfield(gridM, 'text', 'Value', '[1 2; 3 4]', 'FontSize', 12);
            app.MatrixA.Layout.Row = 2; app.MatrixA.Layout.Column = [1 2];

            lB = uilabel(gridM, 'Text', 'Matrix B', 'FontWeight', 'bold', 'FontSize', 12);
            lB.Layout.Row = 3; lB.Layout.Column = [1 2];
            app.MatrixB = uieditfield(gridM, 'text', 'Value', '[5 6; 7 8]', 'FontSize', 12);
            app.MatrixB.Layout.Row = 4; app.MatrixB.Layout.Column = [1 2];

            lOp = uilabel(gridM, 'Text', 'Operation', 'FontWeight', 'bold', 'FontSize', 12);
            lOp.Layout.Row = 5; lOp.Layout.Column = [1 2];
            app.MatrixOp = uidropdown(gridM, ...
                'Items', {'Addition','Multiplication','Inverse','Determinant', ...
                          'Transpose','Power','Adjoint','Rank','Eigenvalues','Solve AX=B'}, ...
                'FontSize', 12, ...
                'ValueChangedFcn', @(~,~) app.updateMatrixInputs());
            app.MatrixOp.Layout.Row = 6; app.MatrixOp.Layout.Column = [1 2];

            lPow = uilabel(gridM, 'Text', 'Power  n =', 'FontWeight', 'bold', 'FontSize', 11, 'HorizontalAlignment', 'right');
            lPow.Layout.Row = 7; lPow.Layout.Column = 1;
            app.MatrixPower = uieditfield(gridM, 'numeric', 'Value', 2, 'FontSize', 12);
            app.MatrixPower.Layout.Row = 7; app.MatrixPower.Layout.Column = 2;

            lHint = uilabel(gridM, 'Text', 'Notation: [1 2 3; 4 5 6; 7 8 9]', 'FontSize', 10, 'FontColor', [0.4 0.4 0.4]);
            lHint.Layout.Row = 8; lHint.Layout.Column = [1 2];

            lSpacer = uilabel(gridM, 'Text', '');
            lSpacer.Layout.Row = 9;
            lSpacer.Layout.Column = [1 2];

            lHint3 = uilabel(gridM, 'Text', 'Solve AX=B uses RREF augmented matrix', 'FontSize', 10, 'FontColor', [0.5 0.2 0.5]);
            lHint3.Layout.Row = 11; lHint3.Layout.Column = [1 2];

            app.MatrixBtn = uibutton(gridM, ...
                'Text',       'Compute', ...
                'FontWeight', 'bold', ...
                'FontSize',   14, ...
                'BackgroundColor', [0.95 0.95 0.95], ...
                'FontColor',  [0 0 0], ...
                'ButtonPushedFcn', @(~,~) app.computeMatrix());
            app.MatrixBtn.Layout.Row    = 12;
            app.MatrixBtn.Layout.Column = [1 2];

            % ── CENTER: result ───────────────────────────────────────────
            resPanel = uipanel(mainME, 'Title', 'Result', 'FontWeight', 'bold', 'FontSize', 12);
            inputPanel.BackgroundColor = [1 1 1];
            resPanel.Layout.Column = 2;
            gridR = uigridlayout(resPanel, [1 1]);
            gridR.Padding = [10 10 10 10];
            app.MatrixResult = uitextarea(gridR, 'FontSize', 13, 'FontName', 'Courier New', 'Editable', 'off');
            app.MatrixResult.Layout.Row = 1; app.MatrixResult.Layout.Column = 1;

            % ── RIGHT: step-by-step ──────────────────────────────────────
            stepsPanel = uipanel(mainME, 'Title', 'Step-by-Step Solution', 'FontWeight', 'bold', 'FontSize', 12);
            inputPanel.BackgroundColor = [1 1 1];
            stepsPanel.Layout.Column = 3;
            gridS = uigridlayout(stepsPanel, [1 1]);
            gridS.Padding = [10 10 10 10];
            app.MatrixSteps = uitextarea(gridS, 'FontSize', 11, 'FontName', 'Courier New', 'Editable', 'off');
            app.MatrixSteps.Layout.Row = 1; app.MatrixSteps.Layout.Column = 1;

            %% Initialise
            app.updateInputs();
            app.updateMatrixInputs();

        end % constructor
    end % public methods
end