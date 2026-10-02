"""Geometry for the 둘운완 'Heart-Check' mark.

The mark is a single thick 90-degree stroke (miter join, round caps):
  - short left arm  -> reads as one lobe of a heart  (partner A)
  - long right arm  -> reads as the long stroke of a check (partner B)
Split vertically through the vertex into two tones = two people, one gesture.
Paths are emitted as explicit outlines (no strokes) so every renderer agrees.
"""
import math

S = 1 / math.sqrt(2)


def geom(w=250, La=230, Lb=430, rot=0.0, tip=0.0):
    h = w / 2
    return dict(w=w, h=h, La=La, Lb=Lb, rot=rot, tip=tip)


def _outline_pts(g, V=(0.0, 0.0)):
    """Return left-piece and right-piece outline path strings in a local frame
    where the vertex centerline point is V. Arms at +-45deg from vertical."""
    h, La, Lb = g['h'], g['La'], g['Lb']
    vx, vy = V
    r2 = math.sqrt(2)
    # miter outer point (bottom) and inner point (top of the V notch)
    bot = (vx, vy + h * r2)
    notch = (vx, vy - h * r2)
    # left arm: centerline from V to A = V + La*(-S,-S)
    Ax, Ay = vx - La * S, vy - La * S
    # left arm edges: normal to direction (-S,-S) is (S,-S) [upper-right side] and (-S,S) [lower-left]
    # outer (lower-left) edge runs from bot to A + h*(-S,S); inner edge from notch to A + h*(S,-S)
    Lout = (Ax - h * S, Ay + h * S)
    Lin = (Ax + h * S, Ay - h * S)
    # right arm: B = V + Lb*(S,-S)
    Bx, By = vx + Lb * S, vy - Lb * S
    Rout = (Bx + h * S, By + h * S)
    Rin = (Bx - h * S, By - h * S)
    f = lambda p: f'{p[0]:.2f} {p[1]:.2f}'
    # softened heart tip: quadratic corner through `bot`, split at its midpoint M
    t = g.get('tip', 0)
    EL = (bot[0] - t * S, bot[1] - t * S)
    ER = (bot[0] + t * S, bot[1] - t * S)
    M = (bot[0], bot[1] - t * S / 2)
    cL = ((EL[0] + bot[0]) / 2, (EL[1] + bot[1]) / 2)
    cR = ((ER[0] + bot[0]) / 2, (ER[1] + bot[1]) / 2)
    # Left piece: M -> (tip curve) EL -> Lout -> round cap -> Lin -> notch -> down the split line
    left = (f'M {f(M)} Q {f(cL)} {f(EL)} L {f(Lout)} A {h:.2f} {h:.2f} 0 0 1 {f(Lin)} '
            f'L {f(notch)} Z')
    right = (f'M {f(M)} L {f(notch)} L {f(Rin)} A {h:.2f} {h:.2f} 0 0 1 {f(Rout)} '
             f'L {f(ER)} Q {f(cR)} {f(M)} Z')
    full = (f'M {f(M)} Q {f(cL)} {f(EL)} L {f(Lout)} A {h:.2f} {h:.2f} 0 0 1 {f(Lin)} '
            f'L {f(notch)} L {f(Rin)} A {h:.2f} {h:.2f} 0 0 1 {f(Rout)} L {f(ER)} Q {f(cR)} {f(M)} Z')
    return left, right, full


def sample_points(g, n=400):
    """Boundary sample points of the full mark in the local frame (V at origin), before rotation."""
    h, La, Lb = g['h'], g['La'], g['Lb']
    pts = []
    r2 = math.sqrt(2)
    pts.append((0, h * r2))
    pts.append((0, -h * r2))
    Ax, Ay = -La * S, -La * S
    Bx, By = Lb * S, -Lb * S
    for i in range(n):
        t = 2 * math.pi * i / n
        pts.append((Ax + h * math.cos(t), Ay + h * math.sin(t)))
        pts.append((Bx + h * math.cos(t), By + h * math.sin(t)))
    return pts


def rotate(p, deg):
    a = math.radians(deg)
    return (p[0] * math.cos(a) - p[1] * math.sin(a), p[0] * math.sin(a) + p[1] * math.cos(a))


def min_enclosing_circle(points):
    # simple iterative approx (Badoiu-Clarkson)
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    for i in range(1, 4000):
        far = max(points, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
        cx += (far[0] - cx) / (i + 1)
        cy += (far[1] - cy) / (i + 1)
    r = max(math.hypot(p[0] - cx, p[1] - cy) for p in points)
    return cx, cy, r


def placement(g, canvas=1024, target='bbox', size=640, bias=(0, 0)):
    """Compute transform (scale, translate) placing mark centered on canvas.
    target='bbox': fit the larger bbox side to `size`; target='circle': enclosing circle diameter = size."""
    pts = [rotate(p, g['rot']) for p in sample_points(g)]
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    if target == 'bbox':
        bw, bh = max(xs) - min(xs), max(ys) - min(ys)
        sc = size / max(bw, bh)
        cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
    elif target == 'circle':
        cx, cy, r = min_enclosing_circle(pts)
        sc = size / (2 * r)
    else:  # 'blend': anchor 70% of the way from enclosing-circle centre to bbox centre (optical
        #          balance), then scale so every point stays inside a circle of diameter `size`
        ccx, ccy, _ = min_enclosing_circle(pts)
        bcx, bcy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
        cx, cy = ccx + 0.7 * (bcx - ccx), ccy + 0.7 * (bcy - ccy)
        R = max(math.hypot(p[0] - cx, p[1] - cy) for p in pts)
        sc = size / (2 * R)
    tx = canvas / 2 - cx * sc + bias[0]
    ty = canvas / 2 - cy * sc + bias[1]
    return sc, tx, ty


def mark_group(g, left_fill, right_fill, canvas=1024, target='bbox', size=640, bias=(0, 0), extra=''):
    sc, tx, ty = placement(g, canvas, target, size, bias)
    left, right, full = _outline_pts(g)
    tr = f'translate({tx:.2f} {ty:.2f}) scale({sc:.4f}) rotate({g["rot"]:.2f})'
    if right_fill is None:
        return f'<g transform="{tr}"{extra}><path d="{full}" fill="{left_fill}"/></g>'
    return (f'<g transform="{tr}"{extra}><path d="{left}" fill="{left_fill}"/>'
            f'<path d="{right}" fill="{right_fill}"/></g>')
