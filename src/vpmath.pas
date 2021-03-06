{
  Description: vPlot math unit.

  Copyright (C) 2017-2020 Melchiorre Caruso <melchiorrecaruso@gmail.com>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit vpmath;

{$mode objfpc}

interface

uses
  classes, sysutils, math;

type
  pvppoint = ^tvppoint;
  tvppoint = packed record
    x: double;
    y: double;
  end;

  pvpline = ^tvpline;
  tvpline = packed record
    p0: tvppoint;
    p1: tvppoint;
  end;

  pvplineimp = ^tvplineimp;
  tvplineimp = packed record
    a: double;
    b: double;
    c: double;
  end;

  pvpcircle = ^tvpcircle;
  tvpcircle = packed record
    center: tvppoint;
    radius: double;
  end;

  pvpcircleimp = ^tvpcircleimp;
  tvpcircleimp = packed record
    a: double;
    b: double;
    c: double;
  end;

  pvpcirclearc = ^tvpcirclearc;
  tvpcirclearc = packed record
    center:     tvppoint;
    startangle: double;
    endangle:   double;
    radius:     double;
  end;

  pvpellipse = ^tvpellipse;
  tvpellipse = packed record
    center:  tvppoint;
    radiusx: double;
    radiusy: double;
      angle: double;
  end;

  pvppolygonal = ^tvppolygonal;
  tvppolygonal = array of tvppoint;

// MOVE
procedure move(var point:     tvppoint;     dx, dy: double);
procedure move(var line:      tvpline;      dx, dy: double);
procedure move(var circle:    tvpcircle;    dx, dy: double);
procedure move(var circlearc: tvpcirclearc; dx, dy: double);
procedure move(var polygonal: tvppolygonal; dx, dy: double);

// ROTATE
procedure rotate(var point:     tvppoint;     angle: double);
procedure rotate(var line:      tvpline;      angle: double);
procedure rotate(var circle:    tvpcircle;    angle: double);
procedure rotate(var circlearc: tvpcirclearc; angle: double);
procedure rotate(var polygonal: tvppolygonal; angle: double);

// SCALE
procedure scale(var point:     tvppoint;     factor: double);
procedure scale(var line:      tvpline;      factor: double);
procedure scale(var circle:    tvpcircle;    factor: double);
procedure scale(var circlearc: tvpcirclearc; factor: double);
procedure scale(var polygonal: tvppolygonal; factor: double);

// MIRROR X
procedure mirrorx(var point:     tvppoint    );
procedure mirrorx(var line:      tvpline     );
procedure mirrorx(var circle:    tvpcircle   );
procedure mirrorx(var circlearc: tvpcirclearc);
procedure mirrorx(var polygonal: tvppolygonal);

// MIRROR Y
procedure mirrory(var point:     tvppoint    );
procedure mirrory(var line:      tvpline     );
procedure mirrory(var circle:    tvpcircle   );
procedure mirrory(var circlearc: tvpcirclearc);
procedure mirrory(var polygonal: tvppolygonal);

// INVERT
procedure invert(var line:      tvpline     );
procedure invert(var circle:    tvpcircle   );
procedure invert(var circlearc: tvpcirclearc);
procedure invert(var polygonal: tvppolygonal);

// LENGTH
function length(const line:      tvpline     ): double;
function length(const circle:    tvpcircle   ): double;
function length(const circlearc: tvpcirclearc): double;
function length(const path:      tvppolygonal): double;

// ANGLE
function angle(const line: tvplineimp): double;

// INTERPOLATE
procedure interpolate(const line:      tvpline;      var path: tvppolygonal; value: double);
procedure interpolate(const circle:    tvpcircle;    var path: tvppolygonal; value: double);
procedure interpolate(const circlearc: tvpcirclearc; var path: tvppolygonal; value: double);
procedure interpolate(const polygonal: tvppolygonal; var path: tvppolygonal; value: double);

// ---

function line_by_two_points(const p0, p1: tvppoint): tvplineimp;
function distance_between_two_points(const p0, p1: tvppoint): double;
function distance_from_point_and_line(const p0: tvppoint; const l0: tvplineimp): double;

function intersection_of_two_lines(const l0, l1: tvplineimp): tvppoint;
function intersection_of_line_and_circle(const a0, b0, c0, a1, b1, c1: double; var p0, p1: tvppoint): longint;
function intersection_of_line_and_circle(const l0: tvplineimp; const c1: tvpcircleimp; var p0, p1: tvppoint): longint;
function intersection_of_circle_and_circle(const c0: tvpcircleimp; const c1: tvpcircleimp; var p0, p1: tvppoint): longint;

function circle_by_three_points(const p0, p1, p2: tvppoint): tvpcircleimp;
function circle_by_center_and_radius(const cc: tvppoint; radius: double): tvpcircleimp;
function circlearc_by_three_points(const p0, p1, p2: tvppoint): tvpcirclearc;
function circlearc_by_center_and_two_points(const cc, p0, p1: tvppoint): tvpcirclearc;
function intersection_of_two_circles(const c0, c1: tvpcircleimp; var p1, p2: tvppoint): longint;

function ispointon(const p: tvppoint; const line:      tvpline;      err: single): boolean;
function ispointon(const p: tvppoint; const circle:    tvpcircle;    err: single): boolean;
function ispointon(const p: tvppoint; const circlearc: tvpcirclearc; err: single): boolean;
function ispointon(const p: tvppoint; const polygonal: tvppolygonal; err: single): boolean;

function itsavertex(const p0, p1, p2: tvppoint): boolean;
function itsthesame(const p0, p1: tvppoint): boolean;
procedure smooth(var l0, l1: tvpline; var a0: tvpcirclearc; const radius: double);


implementation

uses
  matrix;

// MOVE

procedure move(var point: tvppoint; dx, dy: double);
begin
  point.x := point.x + dx;
  point.y := point.y + dy;
end;

procedure move(var line: tvpline; dx, dy: double);
begin
  move(line.p0, dx, dy);
  move(line.p1, dx, dy);
end;

procedure move(var circle: tvpcircle; dx, dy: double);
begin
  move(circle.center, dx, dy);
end;

procedure move(var circlearc: tvpcirclearc; dx, dy: double);
begin
  move(circlearc.center, dx, dy);
end;

procedure move(var polygonal: tvppolygonal; dx, dy: double);
var
  i: longint;
begin
  for i := 0 to high(polygonal) do
  begin
    move(polygonal[i], dx, dy);
  end;
end;

// ROTATE

procedure rotate(var point: tvppoint; angle: double);
var
  px, py: double;
  sn, cs: double;
begin
  sincos(angle, sn, cs);
  begin
    px := point.x * cs - point.y * sn;
    py := point.x * sn + point.y * cs;
  end;
  point.x := px;
  point.y := py;
end;

procedure rotate(var line: tvpline; angle: double);
begin
  rotate(line.p0, angle);
  rotate(line.p1, angle);
end;

procedure rotate(var circle: tvpcircle; angle: double);
begin
  rotate(circle.center, angle);
end;

procedure rotate(var circlearc: tvpcirclearc; angle: double);
begin
  rotate(circlearc.center, angle);
  circlearc.startangle := circlearc.startangle + angle;
  circlearc.endangle   := circlearc.endangle   + angle;
end;

procedure rotate(var polygonal: tvppolygonal; angle: double);
var
  i: longint;
begin
  for i := 0 to high(polygonal) do
  begin
    rotate(polygonal[i], angle);
  end;
end;

// SCALE

procedure scale(var point: tvppoint; factor: double);
begin
  point.x := point.x * factor;
  point.y := point.y * factor;
end;

procedure scale(var line: tvpline; factor: double);
begin
  scale(line.p0, factor);
  scale(line.p1, factor);
end;

procedure scale(var circle: tvpcircle; factor: double);
begin
  scale(circle.center, factor);
  circle.radius := circle.radius * factor;
end;

procedure scale(var circlearc: tvpcirclearc; factor: double);
begin
  scale(circlearc.center, factor);
  circlearc.radius := circlearc.radius * factor;
end;

procedure scale(var polygonal: tvppolygonal; factor: double);
var
  i: longint;
begin
  for i := 0 to high(polygonal) do
  begin
    scale(polygonal[i], factor);
  end;
end;

// MIRROR X

procedure mirrorx(var point: tvppoint);
begin
  point.y := -point.y;
end;

procedure mirrorx(var line: tvpline);
begin
  mirrorx(line.p0);
  mirrorx(line.p1);
end;

procedure mirrorx(var circle: tvpcircle);
begin
  mirrorx(circle.center);
end;

procedure mirrorx(var circlearc: tvpcirclearc);
begin
  mirrorx(circlearc.center);
  circlearc.startangle := -circlearc.startangle + 360;
  circlearc.endangle   := -circlearc.endangle   + 360;
end;

procedure mirrorx(var polygonal: tvppolygonal);
var
  i: longint;
begin
  for i := 0 to high(polygonal) do
  begin
    mirrorx(polygonal[i]);
  end;
end;

// MIRROR Y

procedure mirrory(var point: tvppoint);
begin
  point.x := -point.x;
end;

procedure mirrory(var line: tvpline);
begin
  mirrory(line.p0);
  mirrory(line.p1);
end;

procedure mirrory(var circle: tvpcircle);
begin
  mirrory(circle.center);
end;

procedure mirrory(var circlearc: tvpcirclearc);
begin
  mirrory(circlearc.center);
  circlearc.startangle := -circlearc.startangle + 180;
  circlearc.endangle   := -circlearc.endangle   + 180;
end;

procedure mirrory(var polygonal: tvppolygonal);
var
  i: longint;
begin
  for i := 0 to high(polygonal) do
  begin
    mirrory(polygonal[i]);
  end;
end;

// INVERT

procedure invert(var line: tvpline);
var
  t: tvppoint;
begin
  t       := line.p0;
  line.p0 := line.p1;
  line.p1 := t;
end;

procedure invert(var circle: tvpcircle);
begin
  // nothing to do
end;

procedure invert(var circlearc: tvpcirclearc);
var
  t: double;
begin
  t                    := circlearc.startangle;
  circlearc.startangle := circlearc.endangle;
  circlearc.endangle   := t;
end;

procedure invert(var polygonal: tvppolygonal);
var
  i, j: longint;
     t: tvppolygonal;
begin
  setlength(t, system.length(polygonal));

  j := high(polygonal);
  for i := 0 to j do
  begin
    t[i] := polygonal[j-i];
  end;

  for i := 0 to j do
  begin
    polygonal[i] := t[i];
  end;
  setlength(t, 0);
end;

// LENGTH

function length(const line: tvpline): double;
begin
  result := distance_between_two_points(line.p0, line.p1);
end;

function length(const circle: tvpcircle): double;
const
  sweep = 2*pi;
begin
  result := sweep*circle.radius;
end;

function length(const circlearc: tvpcirclearc): double;
var
  sweep: double;
begin
  sweep  := degtorad(abs(circlearc.endangle-circlearc.startangle));
  result := sweep*circlearc.radius;
end;

function length(const path: tvppolygonal): double;
var
  i: longint;
begin
  result := 0;
  for i := 1 to high(path) do
  begin
    result := result + distance_between_two_points(path[i-1], path[i]);
  end;
end;

// ANGLE

function angle(const line: tvplineimp): double;
begin
  if line.b = 0 then
  begin
    if line.a > 0 then
      result := +1/2*pi
    else
    if line.a < 0 then
      result := -1/2*pi
    else
      result := 0;
  end else
  begin
    result := arctan2(line.a, -line.b);
  end;

  if (result < 0) then
  begin
    result := result + (2*pi);
  end;
end;

// INTERPOLATE

procedure interpolate(const line: tvpline; var path: tvppolygonal; value: double);
var
  dx, dy: double;
   i,  j: longint;
begin
   j := max(1, round(distance_between_two_points(line.p0, line.p1)/value));
  dx := (line.p1.x-line.p0.x)/j;
  dy := (line.p1.y-line.p0.y)/j;
  setlength(path, j+1);
  for i := 0 to j do
  begin
    path[i].x := i*dx;
    path[i].y := i*dy;
    move(path[i], line.p0.x,
                  line.p0.y);
  end;
end;

procedure interpolate(const circle: tvpcircle; var path: tvppolygonal; value: double);
var
  i, j: longint;
    ds: double;
begin
   j := max(1, round(length(circle)/value));
  ds := (2*pi)/j;

  setlength(path, j+1);
  for i := 0 to j do
  begin
    path[i].x := circle.radius;
    path[i].y := 0.0;
    rotate(path[i], i*ds);
    move(path[i], circle.center.x,
                  circle.center.y);
  end;
end;

procedure interpolate(const circlearc: tvpcirclearc; var path: tvppolygonal; value: double);
var
  i, j: longint;
    ds: double;
begin
   j := max(1, round(length(circlearc)/value));
  ds := (circlearc.endangle-circlearc.startangle)/j;

  setlength(path, j+1);
  for i := 0 to j do
  begin
    path[i].x := circlearc.radius;
    path[i].y := 0.0;
    rotate(path[i], degtorad(circlearc.startangle+(i*ds)));
    move(path[i], circlearc.center.x,
                  circlearc.center.y);
  end;
end;

procedure interpolate(const polygonal: tvppolygonal; var path: tvppolygonal; value: double);
var
   i, j: longint;
  aline: tvpline;
  alist: tfplist;
  apath: tvppolygonal;
     ap: pvppoint;
begin
  alist := tfplist.create;

  new(ap);
  alist.add(ap);
  ap^ := polygonal[0];

  for i := 0 to system.length(polygonal) - 2 do
  begin
    aline.p0 := polygonal[i  ];
    aline.p1 := polygonal[i+1];

    interpolate(aline, apath, value);
    for j := 1 to high(apath) do
    begin
      new(ap);
      alist.add(ap);
      ap^ := apath[j];
    end;
  end;

  setlength(path, alist.count);
  for i := 0 to alist.count -1 do
  begin
    path[i] := pvppoint(alist[i])^;
    dispose(pvppoint(alist[i]));
  end;
  alist.destroy;
end;

// ---

function line_by_two_points(const p0, p1: tvppoint): tvplineimp;
begin
  result.a :=  p1.y - p0.y;
  result.b :=  p0.x - p1.x;
  result.c := (p1.x - p0.x) * p0.y -(p1.y - p0.y) * p0.x;
end;

function distance_between_two_points(const p0, p1: tvppoint): double;
begin
  result := sqrt(sqr(p1.x - p0.x) + sqr(p1.y - p0.y));
end;

function distance_from_point_and_line(const p0: tvppoint; const l0: tvplineimp): double;
begin
  result := abs(l0.a*p0.x+l0.b*p0.y+l0.c)/sqrt(sqr(l0.a)+sqr(l0.b));
end;

function intersection_of_two_lines(const l0, l1: tvplineimp): tvppoint;
begin
  if (l0.a * l1.b) <> (l0.b * l1.a) then
  begin
    result.x := (-l0.c * l1.b + l0.b * l1.c) / (l0.a * l1.b - l0.b * l1.a);
    result.y := (-l0.c - l0.a * result.x) / (l0.b);
  end else
    raise exception.create('intersection_of_two_lines exception');
end;

function circle_by_three_points(const p0, p1, p2: tvppoint): tvpcircleimp;
var
  cc: tmatrix2_double;
  d0: tmatrix3_double;
  d1: tmatrix3_double;
  d2: tmatrix3_double;
  dd: tmatrix3_double;
  dt: double;
  n0: double;
  n1: double;
  n2: double;
begin
  result.a := 0;
  result.b := 0;
  result.c := 0;
  cc.init(p1.x-p0.x, p1.y-p0.y,
          p2.x-p0.x, p2.y-p0.y);
  if cc.determinant <> 0 then
  begin
    n0 := -sqr(p0.x)-sqr(p0.y);
    n1 := -sqr(p1.x)-sqr(p1.y);
    n2 := -sqr(p2.x)-sqr(p2.y);
    dd.init(p0.x, p0.y, 1,
            p1.x, p1.y, 1,
            p2.x, p2.y, 1);
    d0.init(n0, p0.y, 1,
            n1, p1.y, 1,
            n2, p2.y, 1);
    d1.init(p0.x, n0, 1,
            p1.x, n1, 1,
            p2.x, n2, 1);
    d2.init(p0.x, p0.y, n0,
            p1.x, p1.y, n1,
          p2.x, p2.y, n2);

    dt       := dd.determinant;
    result.a := d0.determinant/dt;
    result.b := d1.determinant/dt;
    result.c := d2.determinant/dt;
  end;
end;

function circle_by_center_and_radius(const cc: tvppoint; radius: double): tvpcircleimp;
begin
  result.a :=  -2*cc.x;
  result.b :=  -2*cc.y;
  result.c := sqr(cc.x)+
              sqr(cc.y)-
              sqr(radius);
end;

function circlearc_by_three_points(const p0, p1, p2: tvppoint): tvpcirclearc;
var
  cc: tvpcircleimp;
  d0: double;
  d1: double;
  d2: double;
begin
  cc := circle_by_three_points(p0, p1, p2);

  result.center.x   := -cc.a/2;
  result.center.y   := -cc.b/2;
  result.radius     := sqrt(sqr(cc.a/2)+sqr(cc.b/2)-cc.c);

  d0 := distance_between_two_points(p0, p1);
  d1 := distance_between_two_points(p1, p2);
  d2 := distance_between_two_points(p2, p0);

  if (d0 > d1) and (d0 > d2) then
  begin
    result.startangle := radtodeg(angle(line_by_two_points(result.center, p0)));
    result.endangle   := radtodeg(angle(line_by_two_points(result.center, p1)));
  end else
  if (d1 > d0) and (d1 > d2) then
  begin
    result.startangle := radtodeg(angle(line_by_two_points(result.center, p1)));
    result.endangle   := radtodeg(angle(line_by_two_points(result.center, p2)));
  end else
  if (d2 > d0) and (d2 > d1) then
  begin
    result.startangle := radtodeg(angle(line_by_two_points(result.center, p2)));
    result.endangle   := radtodeg(angle(line_by_two_points(result.center, p0)));
  end;
end;

function circlearc_by_center_and_two_points(const cc, p0, p1: tvppoint): tvpcirclearc;
begin
  result.center     := cc;
  result.radius     := distance_between_two_points(cc, p0);
  result.startangle := radtodeg(angle(line_by_two_points(cc, p0)));
  result.endangle   := radtodeg(angle(line_by_two_points(cc, p1)));
end;

function intersection_of_two_circles(const c0, c1: tvpcircleimp; var p1, p2: tvppoint): longint;
var
  aa, bb, cc, dd: double;
begin
  aa := 1+sqr((c0.b-c1.b)/(c1.a-c0.a));
  bb := 2*(c0.b-c1.b)/(c1.a-c0.a)*(c0.c-c1.c)/(c1.a-c0.a)+c1.a*(c0.b-c1.b)/(c1.a-c0.a)+c1.b;
  cc := c1.a*(c0.c-c1.c)/(c1.a-c0.a)+sqr((c0.c-c1.c)/(c1.a-c0.a))+c1.c;
  dd := sqr(bb)-4*aa*cc;

  if dd > 0 then
  begin
    result := 2;
    p1.y   := (-bb-sqrt(dd))/(2*aa);
    p2.y   := (-bb+sqrt(dd))/(2*aa);
    p1.x   := ((c0.c-c1.c)+(c0.b-c1.b)*p1.y)/(c1.a-c0.a);
    p2.x   := ((c0.c-c1.c)+(c0.b-c1.b)*p2.y)/(c1.a-c0.a);
  end else
    if dd = 0 then
    begin
      result := 1;
      p1.y   := -bb;
      p1.x   := ((c0.c-c1.c)+(c0.b-c1.b)*p1.y)/(c1.a-c0.a);
      p2     := p1;
    end else
      result := 0;
end;

function equation_grade_2_solver(const a, b, c: double; var t1, t2: double): longint;
const
  err = 0.0001;
var
  d: double;
begin
  d := sqr(b)-4*a*c;
  if d > +err then
  begin
    result := 2;
        t1 := (-b+sqrt(d))/(2*a);
        t2 := (-b-sqrt(d))/(2*a);
  end else
  if d > -err then
  begin
    result := 1;
        t1 := (-b)/(2*a);
        t2 := t1;
  end else
    result := 0;
end;

function intersection_of_line_and_circle(const a0, b0, c0, a1, b1, c1: double; var p0, p1: tvppoint): longint; inline;
var
  a, b, c: double;
begin
  if (a0 <> 0) and (b0 <> 0) then
  begin
    a := 1 + sqr(b0/a0);
    b := 2*(b0/a0)*(c0/a0) -(b0/a0)*a1 + b1;
    c := sqr(c0/a0) -(c0/a0)*a1 + c1;

    result := equation_grade_2_solver(a, b, c, p0.y, p1.y);
    p0.x := -(b0/a0)*p0.y -(c0/a0);
    p1.x := -(b0/a0)*p1.y -(c0/a0);
  end else
  if (b0 <> 0) then
  begin
    a := 1;
    b := a1;
    c := sqr(c0/b0) -(c0/b0)*b1 +c1;

    result := equation_grade_2_solver(a, b, c, p0.x, p1.x);
    p0.y := -(c0/b0);
    p1.y := -(c0/b0);
  end else
  if (a0 <> 0) then
  begin
    a := 1;
    b := b1;
    c := sqr(c0/a0) -(c0/a0)*a1 +c1;

    result := equation_grade_2_solver(a, b, c, p0.y, p1.y);
    p0.x := -(c0/a0);
    p1.x := -(c0/a0);
  end else
    result := 0;
end;

function intersection_of_line_and_circle(const l0: tvplineimp; const c1: tvpcircleimp; var p0, p1: tvppoint): longint; inline;
begin
  result := intersection_of_line_and_circle(l0.a, l0.b, l0.c, c1.a, c1.b, c1.c, p0, p1);
end;

function intersection_of_circle_and_circle(const c0: tvpcircleimp; const c1: tvpcircleimp; var p0, p1: tvppoint): longint;
var
  l0: tvplineimp;
begin
  l0.a := c0.a-c1.a;
  l0.b := c0.b-c1.b;
  l0.c := c0.c-c1.c;

  result := intersection_of_line_and_circle(l0, c1, p0, p1);
end;

function ispointon(const p: tvppoint; const line: tvpline; err: single): boolean;
var
  l0: tvplineimp;
begin
  l0 := line_by_two_points(line.p0, line.p1);
  result := distance_from_point_and_line(p, l0) < err;
  if result then
  begin
    result := (min(line.p0.x, line.p1.x) <= p.x) and
              (max(line.p0.x, line.p1.x) >= p.x);
  end;
end;

function ispointon(const p: tvppoint; const circle: tvpcircle; err: single): boolean;
begin
  result := abs(distance_between_two_points(p, circle.center) - circle.radius) < err;
end;

function ispointon(const p: tvppoint; const circlearc: tvpcirclearc; err: single): boolean;
var
  c0: tvpcircle;
begin
  c0.center := circlearc.center;
  c0.radius := circlearc.radius;

  result := ispointon(p, c0, err);
  if result then
  begin

  end;
end;

function ispointon(const p: tvppoint; const polygonal: tvppolygonal; err: single): boolean;
var
   i: longint;
  l0: tvpline;
begin
  result := false;
  for i := 0 to high(polygonal) -1 do
  begin
    l0.p0 := polygonal[i];
    l0.p1 := polygonal[i+1];

    result := ispointon(p, l0, err);
    if result then
    begin
      exit;
    end;
  end;
end;

function itsavertex(const p0, p1, p2: tvppoint): boolean;
begin
  result :=  abs(angle(line_by_two_points(p1, p2))  -
                 angle(line_by_two_points(p0, p1))) > 1.50;
end;

function itsthesame(const p0, p1: tvppoint): boolean;
begin
  result:= distance_between_two_points(p0, p1) < 0.01;
end;

function incenter(const a, b, c: tvppoint): tvppoint;
var
  aa: double;
  bb: double;
  cc: double;
begin
  aa := distance_between_two_points(b, c);
  bb := distance_between_two_points(a, c);
  cc := distance_between_two_points(a, b);
  result.x := (aa*a.x+bb*b.x+cc*c.x)/(aa+bb+cc);
  result.y := (aa*a.y+bb*b.y+cc*c.y)/(aa+bb+cc);
end;

procedure smooth(var l0, l1: tvpline; var a0: tvpcirclearc; const radius: double);
var
    j: longint;
  l00: tvplineimp;
  l11: tvplineimp;
   p0: tvppoint;
   p1: tvppoint;
   t0: tvppoint;
   t1: tvppoint;
   xx: tvppoint;
  cxx: tvpcircleimp;
  c00: tvpcircleimp;
  c11: tvpcircleimp;

  sweep: double;
begin
  if not itsthesame(l0.p1, l1.p0) then exit;

  writeln('---smoothing---');
  writeln('l0.p0.x=', l0.p0.x:5:2);
  writeln('l0.p0.y=', l0.p0.y:5:2);
  writeln('l0.p1.x=', l0.p1.x:5:2);
  writeln('l0.p1.y=', l0.p1.y:5:2);
  writeln('l1.p0.x=', l1.p0.x:5:2);
  writeln('l1.p0.y=', l1.p0.y:5:2);
  writeln('l1.p1.x=', l1.p1.x:5:2);
  writeln('l1.p1.y=', l1.p1.y:5:2);
  writeln(' radius=',  radius:5:2);

  l00 := line_by_two_points(l0.p0, l0.p1);
  l11 := line_by_two_points(l1.p0, l1.p1);
  cxx := circle_by_center_and_radius (l0.p1, radius);

  j := intersection_of_line_and_circle(l00, cxx, t0, t1);
  if j = 0 then raise exception.create('smooth exception 1 (det<0)');
  if distance_between_two_points(l0.p0, t0) <
     distance_between_two_points(l0.p0, t1) then
    p0 := t0
  else
    p0 := t1;

  c00 := circle_by_center_and_radius(p0, radius);
  writeln('punto intersezione l0, num sol=', j);
  writeln('p0.x=', p0.x:5:2);
  writeln('p0.y=', p0.y:5:2);

  j := intersection_of_line_and_circle(l11, cxx, t0, t1);
  if j = 0 then raise exception.create('smooth exception 2 (det<0)');
  if distance_between_two_points(l1.p1, t0) <
     distance_between_two_points(l1.p1, t1) then
    p1 := t0
  else
    p1 := t1;

  c11 := circle_by_center_and_radius(p1, radius);
  writeln('punto intersezione l1, num sol=', j);
  writeln('p1.x=', p1.x:5:2);
  writeln('p1.y=', p1.y:5:2);

  j := intersection_of_two_circles(c00, c11, t0, t1);
  if j = 0 then raise exception.create('smooth exception 3 (det<0)');
  if itsthesame(l0.p1, t1) then
    xx := t0
  else
    xx := t1;

  a0 := circlearc_by_three_points(xx, p0, p1);

  writeln('arc.start1= ', a0.startangle:5:4);
  writeln('arc.end1  = ', a0.endangle  :5:4);


  if abs(a0.endangle-a0.startangle) > 180 then
  begin
    sweep := 360 - abs(a0.endangle-a0.startangle);

    if (a0.endangle-a0.startangle) > 0 then
    begin
      a0.endangle   := a0.startangle - sweep;
    end else
    begin
      a0.endangle   := a0.startangle + sweep;
    end;
  end;

  writeln('arc.x      = ',          xx.x:5:4);
  writeln('arc.y      = ',          xx.y:5:4);
  writeln('arc.radius = ',     a0.radius:5:4);
  writeln('arc.start  = ', a0.startangle:5:4);
  writeln('arc.end    = ', a0.endangle  :5:4);
end;

// init unit

procedure initializedebug;
begin
  {$IFOPT D+}
  writeln(' VPLOT::START-DEBUGGER');
  {$ENDIF}
end;

procedure finalizedebug;
begin
  {$IFOPT D+}
  writeln(' VPLOT::END-DEBUGGER');
  {$ENDIF}
end;

initialization

  initializedebug;

finalization

  finalizedebug;

end.

