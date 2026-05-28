import numpy as np
import matplotlib.pyplot as plt
import tkinter as tk
from tkinter import ttk, messagebox


BG     = "#121212"
FG     = "#EAEAEA"
BTN    = "#1F1F1F"
ACCENT = "#00ADB5"

TOL = 1e-5          # stopping tolerance (|ea| < TOL*100 %)

# =========================================================
#  ALGORITHM DEFINITIONS
# =========================================================
ALGORITHMS = {
    "Bisection": {
        "title": "Bisection Method",
        "complexity": "O(log₂((b-a)/ε))  ·  Linear convergence",
        "steps": [
            ("1. Prerequisites",
             "Choose a and b such that f(a)·f(b) < 0\n"
             "(a sign change guarantees a root in [a, b])."),
            ("2. Compute midpoint",
             "xR = (a + b) / 2"),
            ("3. Evaluate f(xR)",
             "Calculate f(xR) at the midpoint."),
            ("4. Update bracket",
             "If f(a)·f(xR) < 0  →  root is in [a, xR], set b = xR\n"
             "If f(a)·f(xR) > 0  →  root is in [xR, b], set a = xR\n"
             "If f(a)·f(xR) = 0  →  xR is the exact root, STOP."),
            ("5. Check convergence",
             "Compute approximate relative error:\n"
             "|εa| = |xR_new − xR_old| / |xR_new| × 100%\n"
             "If |εa| < εs (stopping criterion), STOP.\n"
             "Otherwise return to Step 2."),
        ]
    },
    "Regula Falsi": {
        "title": "Regula Falsi (False Position)",
        "complexity": "Super-linear convergence (faster than Bisection)",
        "steps": [
            ("1. Prerequisites",
             "Choose a (xL) and b (xU) such that f(a)·f(b) < 0."),
            ("2. Compute xR (similar triangles)",
             "xR = [xU·f(xL) − xL·f(xU)] / [f(xL) − f(xU)]"),
            ("3. Evaluate f(xR)",
             "Calculate f(xR)."),
            ("4. Update bracket",
             "If f(xL)·f(xR) < 0  →  set xU = xR\n"
             "If f(xL)·f(xR) > 0  →  set xL = xR\n"
             "If f(xL)·f(xR) = 0  →  exact root found, STOP."),
            ("5. Check convergence",
             "|εa| = |xR_new − xR_old| / |xR_new| × 100%\n"
             "If |εa| < εs, STOP. Otherwise go to Step 2."),
        ]
    },
    "Newton-Raphson": {
        "title": "Newton-Raphson Method",
        "complexity": "O(n²)  ·  Quadratic convergence (very fast near root)",
        "steps": [
            ("1. Prerequisites",
             "Choose initial guess x₀ close to the root.\n"
             "f(x) must be differentiable near the root."),
            ("2. Compute next iterate",
             "x_{i+1} = x_i − f(x_i) / f′(x_i)"),
            ("3. Derivative check",
             "If f′(x_i) ≈ 0, method fails (flat tangent).\n"
             "Choose a different starting point."),
            ("4. Check convergence",
             "|εa| = |x_{i+1} − x_i| / |x_{i+1}| × 100%\n"
             "If |εa| < εs, STOP. Otherwise set x_i = x_{i+1} and go to Step 2."),
            ("5. Note",
             "Derivative f′(x) is approximated numerically here:\n"
             "f′(x) ≈ [f(x+h) − f(x−h)] / 2h,  h = 10⁻⁵"),
        ]
    },
    "Secant": {
        "title": "Secant Method",
        "complexity": "O(n^1.618)  ·  Super-linear (golden-ratio) convergence",
        "steps": [
            ("1. Prerequisites",
             "Choose two initial guesses x₀ and x₁.\n"
             "No derivative required (unlike Newton-Raphson)."),
            ("2. Compute next iterate",
             "x_{i+1} = x_i − f(x_i) · (x_i − x_{i−1}) / [f(x_i) − f(x_{i−1})]"),
            ("3. Division-by-zero check",
             "If f(x_i) − f(x_{i−1}) = 0, method fails.\n"
             "Choose different initial guesses."),
            ("4. Check convergence",
             "|εa| = |x_{i+1} − x_i| / |x_{i+1}| × 100%\n"
             "If |εa| < εs, STOP. Otherwise shift: x_{i−1} = x_i,  x_i = x_{i+1}."),
            ("5. Note",
             "Uses a secant line through two points instead of the tangent.\n"
             "Requires two starting values but avoids computing f′(x)."),
        ]
    },
    "Incremental": {
        "title": "Incremental Search Method",
        "complexity": "O((b−a)/Δx)  ·  Linear scan, slow but robust",
        "steps": [
            ("1. Prerequisites",
             "Choose interval [a, b] and initial step Δx = (b−a)/20."),
            ("2. Scan for sign change",
             "Evaluate f(xL) and f(xU) = f(xL + Δx).\n"
             "If f(xL)·f(xU) < 0 → sign change found, go to Step 3.\n"
             "Otherwise advance: xL = xU, xU = xL + Δx; repeat."),
            ("3. Refine bracket",
             "When a sign change is detected, reduce step:\n"
             "Δx = Δx / 10\n"
             "Repeat up to 5 refinement levels."),
            ("4. Report root",
             "After sufficient refinement, root ≈ (xL + xU) / 2\n"
             "with bracket [xL, xU]."),
            ("5. Check convergence",
             "|εa| = |xU − xL| / |root| × 100%\n"
             "Reports approximate error of the bracket midpoint."),
        ]
    },
}

def clean_expression(expr):
    import re
    expr = expr.replace(" ", "")
    expr = expr.replace("^",  "**")
    expr = expr.replace("³",  "**3")
    expr = expr.replace("²",  "**2")
    expr = expr.replace("√",  "np.sqrt")
    expr = expr.replace("π",  "np.pi")
    expr = re.sub(r'(?<![a-zA-Z])e(?![a-zA-Z])', 'np.e', expr)
    expr = expr.replace("sin", "np.sin")
    expr = expr.replace("cos", "np.cos")
    expr = expr.replace("tan", "np.tan")
    expr = expr.replace("log", "np.log")
    expr = expr.replace("ln",  "np.log")
    return expr

def f(x):
    try:
        expr = clean_expression(entry_func.get())
        allowed = {"x": x, "np": np}
        return eval(expr, {"__builtins__": {}}, allowed)
    except:
        return np.nan

def df(x):
    h = 1e-5
    return (f(x + h) - f(x - h)) / (2 * h)

# =========================================================
#  TABLE HELPERS
# =========================================================
def add_row(*values):
    display = []
    for v in values:
        if v is None:
            display.append("")
        elif isinstance(v, float):
            display.append(round(v, 6))
        else:
            display.append(v)
    table.insert("", "end", values=tuple(display))

def compute_ea(new, old):
    if old is None or new == 0:
        return None
    return abs((new - old) / new) * 100

def clear_table():
    table.delete(*table.get_children())
    result_var.set("")

def set_columns(cols):
    table["columns"] = cols
    for col in cols:
        table.heading(col, text=col)
        table.column(col, anchor="center", width=max(80, 115))

# =========================================================
#  ALGORITHM DISPLAY
# =========================================================
def show_algorithm(method_name):
    """Populate the algorithm panel with the selected method's info."""
    algo = ALGORITHMS.get(method_name)
    if not algo:
        return

    # Update title
    algo_title_var.set(f"📐  {algo['title']}")
    algo_complexity_var.set(f"⏱  {algo['complexity']}")

    # Clear and repopulate the steps
    for widget in algo_steps_frame.winfo_children():
        widget.destroy()

    bg = "#1A1A1A" if dark_mode else "#E8E8E8"
    fg = FG if dark_mode else "#111111"
    accent = ACCENT

    for step_title, step_desc in algo["steps"]:
        row_frame = tk.Frame(algo_steps_frame, bg=bg, bd=0)
        row_frame.pack(fill="x", padx=6, pady=3)

        tk.Label(row_frame, text=step_title,
                 bg=bg, fg=accent,
                 font=("Courier", 9, "bold"),
                 anchor="w").pack(fill="x")

        tk.Label(row_frame, text=step_desc,
                 bg=bg, fg=fg,
                 font=("Courier", 9),
                 anchor="w", justify="left",
                 wraplength=330).pack(fill="x", padx=(12, 0))

        # Separator line
        tk.Frame(algo_steps_frame, height=1,
                 bg="#2A2A2A" if dark_mode else "#CCCCCC").pack(fill="x", padx=6)

    # Highlight the active button
    for name, btn in algo_buttons.items():
        is_active = (name == method_name)
        btn.configure(
            bg=ACCENT if is_active else BTN,
            fg=BG if is_active else FG
        )

# =========================================================
#  ROOT-FINDING METHODS
# =========================================================

# ── BISECTION ─────────────────────────────────────────────────────────────────
def bisection():
    a = float(entry_a.get())
    b = float(entry_b.get())
    clear_table()
    set_columns(("Iter", "xL", "xU", "xR", "f(xR)", "|ea|%"))
    show_algorithm("Bisection")

    if f(a) * f(b) > 0:
        messagebox.showerror("Bisection Error", "f(a) and f(b) must have opposite signs.")
        return

    xr_old = None
    for i in range(1, 51):
        xr  = (a + b) / 2
        fxr = f(xr)
        fxa = f(a)

        ea = compute_ea(xr, xr_old)

        if fxa * fxr < 0:
            b = xr
        elif fxa * fxr > 0:
            a = xr
        else:
            add_row(i, a, b, xr, fxr, 0.0)
            result_var.set(f"Root ≈ {xr:.6f}")
            return

        add_row(i, a, b, xr, fxr, ea if ea is not None else "---")

        if ea is not None and ea < TOL * 100:
            result_var.set(f"Root ≈ {xr:.6f}")
            return

        xr_old = xr

    result_var.set(f"Root ≈ {xr:.6f}  (max iter)")

# ── REGULA FALSI ──────────────────────────────────────────────────────────────
def regula():
    a = float(entry_a.get())
    b = float(entry_b.get())
    clear_table()
    set_columns(("Iter", "xL", "xU", "xR", "|ea|%", "f(xL)", "f(xU)", "f(xR)"))
    show_algorithm("Regula Falsi")

    if f(a) * f(b) > 0:
        messagebox.showerror("Regula Falsi Error", "f(a) and f(b) must have opposite signs.")
        return

    xr_old = None
    for i in range(1, 51):
        fxl = f(a)
        fxu = f(b)

        if fxl - fxu == 0:
            messagebox.showerror("Regula Falsi Error", "f(xL) - f(xU) = 0, cannot continue.")
            return

        xr  = (b * fxl - a * fxu) / (fxl - fxu)
        fxr = f(xr)

        ea = compute_ea(xr, xr_old)

        if fxl * fxr < 0:
            b = xr
        elif fxl * fxr > 0:
            a = xr
        else:
            add_row(i, a, b, xr, 0.0, fxl, fxu, fxr)
            result_var.set(f"Root ≈ {xr:.6f}")
            return

        add_row(i, a, b, xr, ea if ea is not None else "---", fxl, fxu, fxr)

        if ea is not None and ea < TOL * 100:
            result_var.set(f"Root ≈ {xr:.6f}")
            return

        xr_old = xr

    result_var.set(f"Root ≈ {xr:.6f}  (max iter)")

# ── NEWTON-RAPHSON ────────────────────────────────────────────────────────────
def newton():
    x = float(entry_x0.get())
    clear_table()
    set_columns(("Iter", "xi", "f(xi)", "f'(xi)", "x(i+1)", "|ea|%"))
    show_algorithm("Newton-Raphson")

    for i in range(1, 51):
        fx  = f(x)
        dfx = df(x)

        if dfx == 0 or np.isnan(dfx):
            messagebox.showerror("Newton Error", f"Derivative is zero or invalid at x = {x:.6f}")
            return

        x_new = x - fx / dfx
        ea    = compute_ea(x_new, x)
        ea_disp = f"{ea:.6f}" if ea is not None else "---"

        add_row(i, x, fx, dfx, x_new, ea_disp)

        if ea is not None and ea < TOL * 100:
            result_var.set(f"Root ≈ {x_new:.6f}")
            return

        x = x_new

    result_var.set(f"Root ≈ {x:.6f}  (max iter)")

# ── SECANT ────────────────────────────────────────────────────────────────────
def secant():
    x0 = float(entry_a.get())
    x1 = float(entry_b.get())
    clear_table()
    set_columns(("Iter", "x(i-1)", "x(i)", "x(i+1)", "|ea|%", "f(xi-1)", "f(xi)", "f(xi+1)"))
    show_algorithm("Secant")

    for i in range(1, 51):
        f0 = f(x0)
        f1 = f(x1)

        if np.isnan(f0) or np.isnan(f1):
            messagebox.showerror("Secant Error", "Invalid function value.")
            return

        denom = f1 - f0
        if denom == 0:
            messagebox.showerror("Secant Error", "f(x1) - f(x0) = 0, division by zero.")
            return

        x2  = x1 - f1 * (x1 - x0) / denom
        fx2 = f(x2)

        ea = abs((x2 - x1) / x2) * 100 if abs(x2) > 1e-12 else abs(x2 - x1) * 100

        add_row(i, x0, x1, x2, ea, f0, f1, fx2)

        if ea < TOL * 100:
            result_var.set(f"Root ≈ {x2:.6f}")
            return

        x0, x1 = x1, x2

    result_var.set(f"Root ≈ {x2:.6f}  (max iter)")

# ── INCREMENTAL SEARCH ────────────────────────────────────────────────────────
def incremental():
    a = float(entry_a.get())
    b = float(entry_b.get())
    clear_table()
    set_columns(("Iter", "xL", "Δx", "xU", "f(xL)", "f(xU)", "|ea|%"))
    show_algorithm("Incremental")

    if f(a) * f(b) > 0:
        messagebox.showerror("Incremental Error", "No sign change detected in [a, b].")
        return

    h            = (b - a) / 20
    xl           = a
    xu           = xl + h
    REFINE_FACTOR = 10
    MAX_REFINE    = 5
    refine_level  = 0
    i             = 1

    while i <= 200 and xu <= b + 1e-12:
        fxl = f(xl)
        fxu = f(xu)

        if fxl * fxu < 0:
            refine_level += 1
            if refine_level <= MAX_REFINE:
                h  = h / REFINE_FACTOR
                xu = xl + h
                ea = abs(h * REFINE_FACTOR - h) / (h * REFINE_FACTOR) * 100 if refine_level > 1 else None
                add_row(i, xl, h, xu, fxl, fxu, ea if ea is not None else "---")
                i += 1
                continue
            else:
                root = (xl + xu) / 2
                ea   = abs((xu - xl) / root) * 100 if root != 0 else 0
                add_row(i, xl, h, xu, fxl, fxu, round(ea, 6))
                result_var.set(f"Root ≈ {root:.6f}  (bracket [{xl:.6f}, {xu:.6f}])")
                return
        else:
            add_row(i, xl, h, xu, fxl, fxu, "---")

        xl  = xu
        xu  = xl + h
        i  += 1

    root = (xl + xu) / 2
    result_var.set(f"Root ≈ {root:.6f}  (max iter / end of interval)")

# =========================================================
#  GRAPH
# =========================================================
def plot_graph():
    x = np.linspace(-10, 10, 2000)
    y = []
    for i in x:
        try:
            y.append(f(i))
        except:
            y.append(np.nan)

    root_x = None
    if "Root ≈" in result_var.get():
        try:
            root_x = float(result_var.get().split("≈")[1].split()[0])
        except:
            root_x = None

    plt.style.use("dark_background" if dark_mode else "default")
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(x, y, linewidth=2, color=ACCENT, label="f(x)")
    ax.axhline(0, color="gray")
    ax.axvline(0, color="gray")

    if root_x is not None:
        ax.scatter(root_x, 0, color="red", s=80, label="Root")
        ax.annotate(f"Root ≈ {root_x:.5f}", (root_x, 0),
                    textcoords="offset points", xytext=(10, 10), color="red")

    ax.set_title("Graph of f(x)")
    ax.set_xlabel("x")
    ax.set_ylabel("f(x)")
    ax.grid(True)
    ax.legend()
    plt.tight_layout()
    plt.show()

# =========================================================
#  THEME
# =========================================================
dark_mode = True

def set_style(bg, fg, btn_bg, accent):
    style.configure("TButton",    background=btn_bg, foreground=fg)
    style.configure("TLabel",     background=bg,     foreground=fg)
    style.configure("Treeview",   background=btn_bg, foreground=fg, fieldbackground=btn_bg)
    style.map("Treeview", background=[("selected", accent)])

def update_widget_colors(widget, bg, fg, btn_bg, accent):
    cls = type(widget)
    if cls == tk.Label:
        widget.configure(bg=bg, fg=fg)
    elif cls == tk.Button:
        widget.configure(bg=btn_bg, fg=fg, activebackground=accent)
    elif cls == tk.Entry:
        widget.configure(bg=btn_bg, fg=fg, insertbackground=fg)
    elif cls == tk.Text:
        widget.configure(bg=btn_bg, fg=fg, insertbackground=fg)
    for child in widget.winfo_children():
        update_widget_colors(child, bg, fg, btn_bg, accent)

def apply_theme():
    if dark_mode:
        bg, fg, btn_bg, accent = "#121212", "#EAEAEA", "#1F1F1F", "#00ADB5"
    else:
        bg, fg, btn_bg, accent = "#F5F5F5", "#111111", "#FFFFFF", "#007ACC"
    root.configure(bg=bg)
    sidebar.configure(bg="#1A1A1A" if dark_mode else "#E0E0E0")
    content.configure(bg=bg)
    for page in (page_root, page_matrix, page_graph):
        page.configure(bg=bg)

    # Recolor algo panel
    algo_panel_bg = "#1A1A1A" if dark_mode else "#E8E8E8"
    algo_panel.configure(bg=algo_panel_bg)
    algo_header_frame.configure(bg=algo_panel_bg)
    algo_steps_canvas.configure(bg=algo_panel_bg)
    algo_steps_frame.configure(bg=algo_panel_bg)
    algo_title_lbl.configure(bg=algo_panel_bg, fg=accent)
    algo_complexity_lbl.configure(bg=algo_panel_bg, fg=fg)
    algo_btn_frame.configure(bg=algo_panel_bg)
    algo_divider.configure(bg=accent)

    set_style(bg, fg, btn_bg, accent)
    update_widget_colors(root, bg, fg, btn_bg, accent)
    _recolor_matrix_entries()

    # Re-render algorithm steps after theme switch to pick up new colors
    current = algo_title_var.get()
    for method_name in ALGORITHMS:
        if method_name in current:
            show_algorithm(method_name)
            break

def toggle_theme():
    global dark_mode
    dark_mode = not dark_mode
    theme_btn.config(text="🌙 Dark Mode" if dark_mode else "☀️ Light Mode")
    apply_theme()

# =========================================================
#  VARIABLE MATRIX GRID
# =========================================================
matrix_entries: dict = {}

def _entry_bg():
    return "#1F1F1F" if dark_mode else "#FFFFFF"

def _entry_fg():
    return "#EAEAEA" if dark_mode else "#111111"

def _recolor_matrix_entries():
    bg, fg = _entry_bg(), _entry_fg()
    for e in matrix_entries.values():
        e.configure(bg=bg, fg=fg, insertbackground=fg)

def build_matrix_grid(mid: str, rows: int, cols: int):
    container = grid_containers[mid]
    for key in [k for k in matrix_entries if k[0] == mid]:
        matrix_entries.pop(key)
    for widget in container.winfo_children():
        widget.destroy()
    bg, fg = _entry_bg(), _entry_fg()
    for r in range(rows):
        for c in range(cols):
            default = "1" if r == c else "0"
            e = tk.Entry(container, width=5,
                         bg=bg, fg=fg, insertbackground=fg,
                         justify="center", font=("Courier", 11),
                         relief="flat", bd=1,
                         highlightthickness=1,
                         highlightbackground=ACCENT)
            e.insert(0, default)
            e.grid(row=r, column=c, padx=2, pady=2)
            matrix_entries[(mid, r, c)] = e

def get_matrix(mid: str) -> np.ndarray:
    rows = int(size_vars[mid + "_r"].get())
    cols = int(size_vars[mid + "_c"].get())
    data = []
    for r in range(rows):
        row = []
        for c in range(cols):
            raw = matrix_entries[(mid, r, c)].get().strip()
            try:
                row.append(float(raw))
            except ValueError:
                raise ValueError(f"Matrix {mid}: invalid value '{raw}' at [{r},{c}]")
        data.append(row)
    return np.array(data, dtype=float)

def on_size_change(mid: str, *_):
    rows = int(size_vars[mid + "_r"].get())
    cols = int(size_vars[mid + "_c"].get())
    build_matrix_grid(mid, rows, cols)

# =========================================================
#  MATRIX OPERATIONS
# =========================================================
def adjoint_matrix(A):
    n = A.shape[0]
    cof = np.zeros_like(A)
    for i in range(n):
        for j in range(n):
            minor = np.delete(np.delete(A, i, axis=0), j, axis=1)
            cof[i, j] = ((-1) ** (i + j)) * np.linalg.det(minor)
    return cof.T

def show_result(title, res):
    matrix_result_var.set(title)
    matrix_result_text.configure(state="normal")
    matrix_result_text.delete("1.0", tk.END)
    if np.ndim(res) == 0:
        matrix_result_text.insert("1.0", f"{float(res):.6f}")
    else:
        arr = np.atleast_2d(res)
        lines = "\n".join("  ".join(f"{v:10.4f}" for v in row) for row in arr)
        matrix_result_text.insert("1.0", lines)
    matrix_result_text.configure(state="disabled")

def matrix_calc(op):
    try:
        A = get_matrix("A")
    except ValueError as e:
        messagebox.showerror("Input Error", str(e))
        return

    B = None
    needs_b = op in ("add", "sub", "mul", "hadamard", "solve")
    if needs_b:
        try:
            B = get_matrix("B")
        except ValueError as e:
            messagebox.showerror("Input Error", str(e))
            return

    try:
        if op == "add":
            if A.shape != B.shape:
                raise ValueError("A and B must have same shape")
            show_result("A + B", A + B)
        elif op == "sub":
            if A.shape != B.shape:
                raise ValueError("A and B must have same shape")
            show_result("A − B", A - B)
        elif op == "mul":
            if A.shape[1] != B.shape[0]:
                raise ValueError("A cols must match B rows")
            show_result("A × B", A @ B)
        elif op == "hadamard":
            if A.shape != B.shape:
                raise ValueError("A and B must have same shape")
            show_result("A ∘ B", A * B)
        elif op == "solve":
            if A.shape[0] != A.shape[1]:
                raise ValueError("A must be square")
            if A.shape[0] != B.shape[0]:
                raise ValueError("Row mismatch")
            show_result("X (AX=B)", np.linalg.solve(A, B))
        elif op == "detA":
            if A.shape[0] != A.shape[1]:
                raise ValueError("A must be square")
            show_result("det(A)", round(np.linalg.det(A), 6))
        elif op == "invA":
            if A.shape[0] != A.shape[1]:
                raise ValueError("A must be square")
            show_result("A⁻¹", np.linalg.inv(A))
        elif op == "transA":
            show_result("Aᵀ", A.T)
        elif op == "adjA":
            if A.shape[0] != A.shape[1]:
                raise ValueError("A must be square")
            show_result("adj(A)", adjoint_matrix(A))
        elif op == "powerA":
            if A.shape[0] != A.shape[1]:
                raise ValueError("A must be square")
            show_result("A²", np.linalg.matrix_power(A, 2))
        elif op == "detB":
            if B.shape[0] != B.shape[1]:
                raise ValueError("B must be square")
            show_result("det(B)", round(np.linalg.det(B), 6))
        elif op == "invB":
            if B.shape[0] != B.shape[1]:
                raise ValueError("B must be square")
            show_result("B⁻¹", np.linalg.inv(B))
        elif op == "transB":
            show_result("Bᵀ", B.T)
        elif op == "adjB":
            if B.shape[0] != B.shape[1]:
                raise ValueError("B must be square")
            show_result("adj(B)", adjoint_matrix(B))
        elif op == "powerB":
            if B.shape[0] != B.shape[1]:
                raise ValueError("B must be square")
            show_result("B²", np.linalg.matrix_power(B, 2))
        else:
            messagebox.showerror("Error", "Unknown operation")
    except Exception as e:
        messagebox.showerror("Matrix Error", str(e))

# =========================================================
#  GUI SETUP
# =========================================================
root = tk.Tk()
root.title("Numerical Methods")
root.geometry("1280x820")
root.configure(bg=BG)

style = ttk.Style()
style.theme_use("default")
style.configure("Treeview",
                background=BTN, foreground=FG,
                rowheight=25, fieldbackground=BTN)
style.map("Treeview", background=[("selected", ACCENT)])

topbar = tk.Frame(root, bg=BG)
topbar.pack(fill="x", padx=10, pady=4)

theme_btn = tk.Button(topbar, text="🌙 Dark Mode",
                      command=toggle_theme,
                      bg=BTN, fg=FG, relief="flat", padx=8)
theme_btn.pack(side="right")

main_container = tk.Frame(root, bg=BG)
main_container.pack(fill="both", expand=True)

sidebar = tk.Frame(main_container, width=180, bg="#1A1A1A")
sidebar.pack(side="left", fill="y")
sidebar.pack_propagate(False)

content = tk.Frame(main_container, bg=BG)
content.pack(side="right", fill="both", expand=True)

tk.Label(sidebar, text="NUMERICAL\nMETHODS",
         bg="#1A1A1A", fg=ACCENT,
         font=("Arial", 13, "bold")).pack(pady=20)

def show_page(page):
    page.tkraise()

pages = {}
for name in ("root", "matrix", "graph"):
    p = tk.Frame(content, bg=BG)
    p.place(relwidth=1, relheight=1)
    pages[name] = p

page_root   = pages["root"]
page_matrix = pages["matrix"]
page_graph  = pages["graph"]

for label, page_ref in [("Root Methods", "root"),
                        ("Matrix",       "matrix"),
                        ("Graph",        "graph")]:
    tk.Button(sidebar, text=label,
              command=lambda p=page_ref: show_page(pages[p]),
              bg=BTN, fg=FG, relief="flat", width=18
              ).pack(pady=8)

# =========================================================
#  ROOT PAGE  —  two-column layout
# =========================================================

# ── Header ──────────────────────────────────────────────
tk.Label(page_root, text="⚡ Numerical Methods Solver",
         font=("Arial", 20, "bold"), bg=BG, fg=ACCENT).pack(pady=(12, 2))
tk.Label(page_root, text="Root Finding",
         font=("Arial", 11), bg=BG, fg=FG).pack()
tk.Frame(page_root, height=2, bg=ACCENT).pack(fill="x", pady=6)

# ── Two-column container ─────────────────────────────────
root_body = tk.Frame(page_root, bg=BG)
root_body.pack(fill="both", expand=True, padx=6)

# Left column — inputs, buttons, table, result
left_col = tk.Frame(root_body, bg=BG)
left_col.pack(side="left", fill="both", expand=True)

# Right column — algorithm panel
right_col = tk.Frame(root_body, bg=BG)
right_col.pack(side="right", fill="y", padx=(8, 4))

# ── Inputs ───────────────────────────────────────────────
frame_input = tk.Frame(left_col, bg=BG)
frame_input.pack(pady=(4, 0))

for row_idx, (lbl, default) in enumerate([
        ("f(x) =", "x^3 - x - 2"),
        ("a",      "1"),
        ("b",      "2"),
        ("x0",     "1.5")]):
    tk.Label(frame_input, text=lbl, bg=BG, fg=FG, width=6, anchor="e").grid(
        row=row_idx, column=0, padx=4, pady=3)
    e = tk.Entry(frame_input, bg=BTN, fg=FG, insertbackground=FG, width=20)
    e.insert(0, default)
    e.grid(row=row_idx, column=1, padx=4, pady=3)
    if lbl == "f(x) =":  entry_func = e
    elif lbl == "a":      entry_a    = e
    elif lbl == "b":      entry_b    = e
    elif lbl == "x0":     entry_x0   = e

# ── Method buttons ────────────────────────────────────────
frame_buttons = tk.Frame(left_col, bg=BG)
frame_buttons.pack(pady=6)

algo_buttons = {}  # keep references for highlight toggling

for col, (txt, cmd) in enumerate([
        ("Bisection",    bisection),
        ("Regula Falsi", regula),
        ("Newton",       newton),
        ("Secant",       secant),
        ("Incremental",  incremental),
        ("Graph",        plot_graph)]):
    b = tk.Button(frame_buttons, text=txt, command=cmd,
                  bg=BTN, fg=FG, activebackground=ACCENT,
                  relief="flat", width=12)
    b.grid(row=0, column=col, padx=4)
    if txt != "Graph":
        algo_buttons[txt] = b

# ── Table ────────────────────────────────────────────────
columns = ("Iter", "xL", "xU", "xR", "f(xR)", "|ea|%")
table = ttk.Treeview(left_col, columns=columns, show="headings", height=10)
for col in columns:
    table.heading(col, text=col)
    table.column(col, anchor="center", width=115)
table.pack(pady=6)

scrollbar = ttk.Scrollbar(left_col, orient="vertical", command=table.yview)
table.configure(yscrollcommand=scrollbar.set)
scrollbar.pack(side="right", fill="y")

result_var = tk.StringVar()
tk.Label(left_col, textvariable=result_var,
         bg=BG, fg=ACCENT, font=("Arial", 13)).pack()

# =========================================================
#  ALGORITHM PANEL  (right column)
# =========================================================
algo_panel_bg = "#1A1A1A"

algo_panel = tk.Frame(right_col, bg=algo_panel_bg, bd=1, relief="solid", width=370)
algo_panel.pack(fill="y", expand=True)
algo_panel.pack_propagate(False)

# Header section
algo_header_frame = tk.Frame(algo_panel, bg=algo_panel_bg)
algo_header_frame.pack(fill="x", padx=8, pady=(10, 4))

tk.Label(algo_header_frame, text="ALGORITHM",
         bg=algo_panel_bg, fg="#555555",
         font=("Courier", 8, "bold")).pack(anchor="w")

algo_title_var = tk.StringVar(value="📐  Select a method to view its algorithm")
algo_title_lbl = tk.Label(algo_header_frame, textvariable=algo_title_var,
                           bg=algo_panel_bg, fg=ACCENT,
                           font=("Arial", 11, "bold"),
                           wraplength=340, justify="left")
algo_title_lbl.pack(anchor="w", pady=(2, 0))

algo_complexity_var = tk.StringVar(value="")
algo_complexity_lbl = tk.Label(algo_header_frame, textvariable=algo_complexity_var,
                                bg=algo_panel_bg, fg=FG,
                                font=("Courier", 8),
                                wraplength=340, justify="left")
algo_complexity_lbl.pack(anchor="w")

# Divider
algo_divider = tk.Frame(algo_panel, height=1, bg=ACCENT)
algo_divider.pack(fill="x", pady=(4, 0))

# Quick-access buttons for each algorithm (inside panel)
algo_btn_frame = tk.Frame(algo_panel, bg=algo_panel_bg)
algo_btn_frame.pack(fill="x", padx=6, pady=4)

tk.Label(algo_btn_frame, text="Quick view:",
         bg=algo_panel_bg, fg="#555555",
         font=("Courier", 8)).pack(side="left", padx=(0, 4))

for method_name in ALGORITHMS:
    short = method_name.split()[0]  # first word for brevity
    tk.Button(algo_btn_frame,
              text=short,
              command=lambda m=method_name: show_algorithm(m),
              bg=BTN, fg=FG, activebackground=ACCENT,
              relief="flat", font=("Arial", 8), padx=4
              ).pack(side="left", padx=2)

# Scrollable steps area
steps_outer = tk.Frame(algo_panel, bg=algo_panel_bg)
steps_outer.pack(fill="both", expand=True, padx=4, pady=4)

algo_steps_canvas = tk.Canvas(steps_outer, bg=algo_panel_bg,
                               highlightthickness=0)
algo_steps_canvas.pack(side="left", fill="both", expand=True)

steps_scrollbar = ttk.Scrollbar(steps_outer, orient="vertical",
                                  command=algo_steps_canvas.yview)
steps_scrollbar.pack(side="right", fill="y")
algo_steps_canvas.configure(yscrollcommand=steps_scrollbar.set)

algo_steps_frame = tk.Frame(algo_steps_canvas, bg=algo_panel_bg)
canvas_window = algo_steps_canvas.create_window((0, 0), window=algo_steps_frame,
                                                  anchor="nw")

def _on_steps_configure(event):
    algo_steps_canvas.configure(scrollregion=algo_steps_canvas.bbox("all"))
    algo_steps_canvas.itemconfig(canvas_window,
                                  width=algo_steps_canvas.winfo_width())

algo_steps_frame.bind("<Configure>", _on_steps_configure)
algo_steps_canvas.bind("<Configure>",
    lambda e: algo_steps_canvas.itemconfig(canvas_window, width=e.width))

# Mouse-wheel scrolling on the panel
def _on_mousewheel(event):
    algo_steps_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")

algo_steps_canvas.bind_all("<MouseWheel>", _on_mousewheel)

# =========================================================
#  GRAPH PAGE
# =========================================================
tk.Label(page_graph, text="Function Graphing",
         bg=BG, fg=ACCENT, font=("Arial", 16, "bold")).pack(pady=20)
tk.Label(page_graph,
         text="Uses f(x) entered on the Root Methods page.",
         bg=BG, fg=FG).pack()
tk.Button(page_graph, text="Plot Graph", command=plot_graph,
          bg=BTN, fg=FG, width=20).pack(pady=20)

# =========================================================
#  MATRIX PAGE
# =========================================================
tk.Label(page_matrix, text="Matrix Calculator",
         font=("Arial", 16, "bold"), bg=BG, fg=ACCENT).pack(pady=(10, 4))
tk.Frame(page_matrix, height=2, bg=ACCENT).pack(fill="x", pady=4)

grids_outer = tk.Frame(page_matrix, bg=BG)
grids_outer.pack(padx=10, pady=6)

size_vars       = {}
grid_containers = {}

SIZE_OPTS = ["1", "2", "3", "4", "5"]

for col_idx, mid in enumerate(("A", "B")):
    panel = tk.Frame(grids_outer, bg=BTN, bd=1, relief="solid")
    panel.grid(row=0, column=col_idx, padx=12, pady=4, sticky="n")

    tk.Label(panel, text=f"Matrix {mid}",
             bg=BTN, fg=ACCENT, font=("Arial", 12, "bold")).pack(pady=(6, 2))

    ctrl = tk.Frame(panel, bg=BTN)
    ctrl.pack(pady=4)

    tk.Label(ctrl, text="Rows", bg=BTN, fg=FG, font=("Arial", 9)).grid(row=0, column=0)
    rv = tk.StringVar(value="3")
    size_vars[mid + "_r"] = rv
    rb = ttk.Combobox(ctrl, textvariable=rv, values=SIZE_OPTS, width=3, state="readonly")
    rb.grid(row=0, column=1, padx=4)
    rb.bind("<<ComboboxSelected>>", lambda e, m=mid: on_size_change(m))

    tk.Label(ctrl, text="Cols", bg=BTN, fg=FG, font=("Arial", 9)).grid(row=0, column=2)
    cv = tk.StringVar(value="3")
    size_vars[mid + "_c"] = cv
    cb = ttk.Combobox(ctrl, textvariable=cv, values=SIZE_OPTS, width=3, state="readonly")
    cb.grid(row=0, column=3, padx=4)
    cb.bind("<<ComboboxSelected>>", lambda e, m=mid: on_size_change(m))

    gc = tk.Frame(panel, bg=BTN)
    gc.pack(padx=8, pady=(4, 10))
    grid_containers[mid] = gc

build_matrix_grid("A", 3, 3)
build_matrix_grid("B", 3, 3)

ops_frame = tk.Frame(page_matrix, bg=BG)
ops_frame.pack(fill="x", pady=6)

def op_btn(parent, text, op, r, c):
    tk.Button(parent, text=text,
              command=lambda: matrix_calc(op),
              bg=BTN, fg=FG, activebackground=ACCENT,
              relief="flat", width=15
              ).grid(row=r, column=c, padx=4, pady=3)

ops_frame.grid_columnconfigure(0, weight=1)
ops_frame.grid_columnconfigure(1, weight=1)
ops_frame.grid_columnconfigure(2, weight=1)

a_only = tk.LabelFrame(ops_frame, text=" Operations on A ",
                       bg=BG, fg=ACCENT, font=("Arial", 10))
a_only.grid(row=0, column=0, padx=10, pady=5, sticky="n")
for idx, (lbl, op) in enumerate([("det(A)","detA"),("inv(A)","invA"),
                                  ("Aᵀ","transA"),("adj(A)","adjA"),("A²","powerA")]):
    op_btn(a_only, lbl, op, idx//2, idx%2)

b_only = tk.LabelFrame(ops_frame, text=" Operations on B ",
                       bg=BG, fg=ACCENT, font=("Arial", 10))
b_only.grid(row=0, column=1, padx=10, pady=5, sticky="n")
for idx, (lbl, op) in enumerate([("det(B)","detB"),("inv(B)","invB"),
                                  ("Bᵀ","transB"),("adj(B)","adjB"),("B²","powerB")]):
    op_btn(b_only, lbl, op, idx//2, idx%2)

ab = tk.LabelFrame(ops_frame, text=" Operations on A & B ",
                   bg=BG, fg=ACCENT, font=("Arial", 10))
ab.grid(row=0, column=2, padx=10, pady=5, sticky="n")
for idx, (lbl, op) in enumerate([("A + B","add"),("A − B","sub"),
                                  ("A × B","mul"),("A ∘ B","hadamard"),("Solve AX=B","solve")]):
    op_btn(ab, lbl, op, idx//2, idx%2)

res_panel = tk.Frame(page_matrix, bg=BG)
res_panel.pack(fill="both", expand=True, padx=12, pady=6)

matrix_result_var = tk.StringVar(value="Result")
tk.Label(res_panel, textvariable=matrix_result_var,
         bg=BG, fg=ACCENT, font=("Arial", 11, "bold")).pack(anchor="w")

matrix_result_text = tk.Text(res_panel, height=6, width=80,
                             bg=BTN, fg=FG, insertbackground=FG,
                             font=("Courier", 11), state="disabled",
                             relief="flat", bd=0)
matrix_result_text.pack(fill="both", expand=True)

# =========================================================
#  LAUNCH
# =========================================================
show_page(page_root)
apply_theme()

# Pre-load Bisection algorithm on startup
show_algorithm("Bisection")

root.mainloop()