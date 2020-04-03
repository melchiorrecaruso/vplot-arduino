{
  Description: Driver class.

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

unit vpdriver;

{$mode objfpc}

interface

uses
  classes, math, sysutils, vpmath, vpserial, vpsetting, vputils;

const
  vpserver_getxcount = 240;
  vpserver_getycount = 241;
  vpserver_getzcount = 242;
  vpserver_getrampkb = 243;
  vpserver_getrampkm = 244;

  vpserver_setxcount = 230;
  vpserver_setycount = 231;
  vpserver_setzcount = 232;
  vpserver_setrampkb = 233;
  vpserver_setrampkm = 234;

type
  tvpdriver = class(tthread)
  private
    fenabled: boolean;
    fmessage: string;
    frampkb: longint;
    frampkl: longint;
    frampkm: longint;
    fserial: tvpserialstream;
    fstream: tmemorystream;
    fxcount: longint;
    fycount: longint;
    fzcount: longint;
    fonerror: tthreadmethod;
    foninit: tthreadmethod;
    fonstart: tthreadmethod;
    fonstop: tthreadmethod;
    fontick: tthreadmethod;
    procedure createramps;
  public
    constructor create(aserial: tvpserialstream);
    destructor destroy; override;
    procedure init;
    procedure move(cx, cy: longint);
    procedure movez(cz: longint);
    procedure execute; override;
  published
    property enabled: boolean       read fenabled write fenabled;
    property message: string        read fmessage;
    property onerror: tthreadmethod read fonerror write fonerror;
    property oninit:  tthreadmethod read foninit  write foninit;
    property onstart: tthreadmethod read fonstart write fonstart;
    property onstop:  tthreadmethod read fonstop  write fonstop;
    property ontick:  tthreadmethod read fontick  write fontick;
    property xcount:  longint       read fxcount;
    property ycount:  longint       read fycount;
    property zcount:  longint       read fzcount;
  end;

  tvpdriverengine = class
  private
    fsetting: tvpsetting;
    fpage: array[0..2, 0..2] of tvppoint;
  public
    constructor create(asetting: tvpsetting);
    destructor destroy; override;
    function  calclength0(const p, t0: tvppoint; r0: vpfloat): vpfloat;
    function  calclength1(const p, t1: tvppoint; r1: vpfloat): vpfloat;
    procedure calclengths(const p: tvppoint; out lx, ly: vpfloat);
    procedure calcsteps  (const p: tvppoint; out cx, cy: longint);
    procedure debug;
  end;


  function serverget(serial: tvpserialstream; id: byte; var value: longint): boolean;
  function serverset(serial: tvpserialstream; id: byte;     value: longint): boolean;

var
  driver:       tvpdriver       = nil;
  driverengine: tvpdriverengine = nil;

implementation

// server get/set routines

function serverget(serial: tvpserialstream; id: byte; var value: longint): boolean;
var
  cc: byte;
begin
  result := serial.connected;
  if result then
  begin
    serial.clear;
    result := (serial.write(id,    sizeof(id   )) = sizeof(id   )) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   )) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   )) and
              (serial.read (value, sizeof(value)) = sizeof(value));

    result := result and (cc = id);
  end;
end;

function serverset(serial: tvpserialstream; id: byte; value: longint): boolean;
var
  cc: byte;
begin
  result := serial.connected;
  if result then
  begin
    serial.clear;
    result := (serial.write(id,    sizeof(id   )) = sizeof(id   )) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   )) and
              (serial.write(value, sizeof(value)) = sizeof(value)) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   ));

    result := result and (cc = id);
  end;
end;

// calculate belt lengths

constructor tvpdriverengine.create(asetting: tvpsetting);
begin
  inherited create;
  fsetting      :=  asetting;
  fpage[0, 0].x := -fsetting.pagewidth  / 2;
  fpage[0, 0].y := +fsetting.pageheight / 2;
  fpage[0, 1].x := +0.000;
  fpage[0, 1].y := +fsetting.pageheight / 2;
  fpage[0, 2].x := +fsetting.pagewidth  / 2;
  fpage[0, 2].y := +fsetting.pageheight / 2;

  fpage[1, 0].x := -fsetting.pagewidth  / 2;
  fpage[1, 0].y := +0.000;
  fpage[1, 1].y := +0.000;
  fpage[1, 1].y := +0.000;
  fpage[1, 2].x := +0.000;
  fpage[1, 2].x := +fsetting.pagewidth  / 2;

  fpage[2, 0].x := -fsetting.pagewidth  / 2;
  fpage[2, 0].y := -fsetting.pageheight / 2;
  fpage[2, 1].x := +0.000;
  fpage[2, 1].y := -fsetting.pageheight / 2;
  fpage[2, 2].x := +fsetting.pagewidth  / 2;
  fpage[2, 2].y := -fsetting.pageheight / 2;
end;

destructor tvpdriverengine.destroy;
begin
  inherited destroy;
end;

function tvpdriverengine.calclength0(const p, t0: tvppoint; r0: vpfloat): vpfloat;
var
      a0: vpfloat;
  c0, cx: tvpcircleimp;
  s0, sx: tvppoint;
begin
  //find tangent point t0
  result := sqrt(sqr(distance_between_two_points(t0, p))-sqr(r0));
  c0 := circle_by_center_and_radius(t0, r0);
  cx := circle_by_center_and_radius(p, result);
  if intersection_of_two_circles(c0, cx, s0, sx) = 0 then
    raise exception.create('intersection_of_two_circles [c0c2]');
  a0 := angle(line_by_two_points(s0, t0));
  result := result + a0*r0;
end;

function tvpdriverengine.calclength1(const p, t1: tvppoint; r1: vpfloat): vpfloat;
var
      a1: vpfloat;
  c1, cx: tvpcircleimp;
  s1, sx: tvppoint;
begin
  //find tangent point t1
  result := sqrt(sqr(distance_between_two_points(t1, p))-sqr(r1));
  c1 := circle_by_center_and_radius(t1, r1);
  cx := circle_by_center_and_radius(p, result);
  if intersection_of_two_circles(c1, cx, s1, sx) = 0 then
    raise exception.create('intersection_of_two_circles [c1c2]');
  a1 := pi-angle(line_by_two_points(s1, t1));
  result := result + a1*r1;
end;

procedure tvpdriverengine.calclengths(const p: tvppoint; out lx, ly: vpfloat);
var
      a0, a1: vpfloat;
  c0, c1, cx: tvpcircleimp;
  s0, s1, sx: tvppoint;
      t0, t1: tvppoint;
begin
  //find tangent point t0
  t0 := setting.point0;
  lx := sqrt(sqr(distance_between_two_points(t0, p))-sqr(setting.mxradius));
  c0 := circle_by_center_and_radius(t0, setting.mxradius);
  cx := circle_by_center_and_radius(p, lx);
  if intersection_of_two_circles(c0, cx, s0, sx) = 0 then
    raise exception.create('intersection_of_two_circles [c0c2]');
  a0 := angle(line_by_two_points(s0, t0));
  lx := lx + a0*setting.mxradius;
  //find tangent point t1
  t1 := setting.point1;
  ly := sqrt(sqr(distance_between_two_points(t1, p))-sqr(setting.myradius));
  c1 := circle_by_center_and_radius(t1, setting.myradius);
  cx := circle_by_center_and_radius(p, ly);
  if intersection_of_two_circles(c1, cx, s1, sx) = 0 then
    raise exception.create('intersection_of_two_circles [c1c2]');
  a1 := pi-angle(line_by_two_points(s1, t1));
  ly := ly + a1*setting.myradius;
end;

procedure tvpdriverengine.calcsteps(const p: tvppoint; out cx, cy: longint);
var
  lx, ly: vpfloat;
begin
  calclengths(p, lx, ly);
  // calculate steps
  cx := round(lx/setting.mxratio);
  cy := round(ly/setting.myratio);
end;

procedure tvpdriverengine.debug;
const
  str = '  CALC::PNT.X       = %12.5f  PNT.Y  = %12.5f  |  LX = %12.5f  LY = %12.5f' ;
var
  i: longint;
  j: longint;
  lx: vpfloat;
  ly: vpfloat;
  offsetx: vpfloat;
  offsety: vpfloat;
  p: tvppoint;
begin
  if enabledebug then
  begin
    offsetx := fsetting.point8.x;
    offsety := fsetting.point8.y +
      (fsetting.pageheight)*fsetting.point9factor + fsetting.point9offset;

    for i := 0 to 2 do
      for j := 0 to 2 do
      begin
        p   := fpage[i, j];
        p.x := p.x + offsetx;
        p.y := p.y + offsety;
        calclengths(p, lx, ly);

        writeln(format(str, [p.x, p.y, lx, ly]));
      end;
  end;
end;

// tvpdriver

constructor tvpdriver.create(aserial: tvpserialstream);
begin
  fenabled := true;
  fmessage := '';
  frampkb  := setting.rampkb;
  frampkl  := setting.rampkl;
  frampkm  := setting.rampkm;
  fserial  := aserial;
  fstream  := tmemorystream.create;
  fxcount  := 0;
  fycount  := 0;
  fzcount  := 0;

  fonerror := nil;
  foninit  := nil;
  fonstart := nil;
  fonstop  := nil;
  fontick  := nil;
  freeonterminate := true;
  inherited create(true);
end;

destructor tvpdriver.destroy;
begin
  fserial := nil;
  fstream.clear;
  fstream.destroy;
  inherited destroy;
end;

procedure tvpdriver.init;
begin
  fstream.clear;
  fserial.clear;
  if (not serverget(fserial, vpserver_getxcount, fxcount)) or
     (not serverget(fserial, vpserver_getycount, fycount)) or
     (not serverget(fserial, vpserver_getzcount, fzcount)) or
     (not serverset(fserial, vpserver_setrampkb, frampkb)) or
     (not serverset(fserial, vpserver_setrampkm, frampkm))then
  begin
    fmessage := 'Unable connecting to server !';
    if assigned(fonerror) then
      synchronize(fonerror);
  end;
end;

procedure tvpdriver.move(cx, cy: longint);
var
  b0: byte;
  b1: byte;
  dx: longint;
  dy: longint;
begin
  b0 := %00000000;
  dx := (cx - fxcount);
  dy := (cy - fycount);
  if (dx < 0) then setbit1(b0, 1);
  if (dy < 0) then setbit1(b0, 3);

  dx := abs(dx);
  dy := abs(dy);
  while (dx > 0) or (dy > 0) do
  begin
    b1 := b0;
    if dx > 0 then
    begin
      setbit1(b1, 0);
      dec(dx);
    end;

    if dy > 0 then
    begin
      setbit1(b1, 2);
      dec(dy);
    end;
    fstream.write(b1, sizeof(b1));
  end;
  fxcount := cx;
  fycount := cy;
end;

procedure tvpdriver.movez(cz : longint);
var
   b0: byte;
   b1: byte;
   dz: longint;
begin
  b0 := %00000000;
  dz := (cz - fzcount);
  if (dz < 0) then setbit1(b0, 5);

  dz := abs(dz);
  while (dz > 0) do
  begin
    b1 := b0;
    if dz > 0 then
    begin
      setbit1(b1, 4);
      dec(dz);
    end;
    fstream.write(b1, sizeof(b1));
  end;
  fzcount := cz;
end;

procedure tvpdriver.createramps;
const
  ds    = 2;
  maxdx = 4;
  maxdy = 4;
var
  bufsize: longint;
  buf: array of byte;
  dx:  array of longint;
  dy:  array of longint;
  i, j, k, r: longint;
begin
  bufsize := fstream.size;
  if bufsize > 0 then
  begin
    setlength(dx,  bufsize);
    setlength(dy,  bufsize);
    setlength(buf, bufsize);
    fstream.seek(0, sofrombeginning);
    fstream.read(buf[0], bufsize);

    // store data in dx and dy arrays
    for i := 0 to bufsize -1 do
    begin
      dx[i] := 0;
      dy[i] := 0;
      for j := max(i-ds, 0) to min(i+ds, bufsize-1) do
      begin
        if getbit1(buf[j], 0) then
        begin
          if getbit1(buf[j], 1) then
            dec(dx[i])
          else
            inc(dx[i]);
        end;

        if getbit1(buf[j], 2) then
        begin
          if getbit1(buf[j], 3) then
            dec(dy[i])
          else
            inc(dy[i]);
        end;
      end;
    end;

    i := 0;
    j := i + 1;
    while (j < bufsize) do
    begin
      k := i;
      while (abs(dx[j] - dx[k]) <= maxdx) and
            (abs(dy[j] - dy[k]) <= maxdy) do
      begin
        if j = bufsize -1 then break;
        inc(j);

        if (j - k) > (2*frampkl) then
        begin
          k := j - frampkl;
        end;
      end;

      if j - i > 10 then
      begin
        r := min((j-i) div 2, frampkl);
        for k := (i) to (i+r-1) do
          setbit1(buf[k], 6);

        for k := (j-r+1) to (j) do
          setbit1(buf[k], 7);
      end;
      i := j + 1;
      j := i + 1;
    end;
    fstream.seek(0, sofrombeginning);
    fstream.write(buf[0], bufsize);
    setlength(dx,  0);
    setlength(dy,  0);
    setlength(buf, 0);
  end;
end;

procedure tvpdriver.execute;
var
  buf: array[0..59]of byte;
  bufsize: byte;
  i: longint;
begin
  fserial.clear;
  if assigned(onstart) then
    synchronize(fonstart);
  createramps;

  fstream.seek(0, sofrombeginning);
  bufsize := fstream.read(buf, system.length(buf));
  while (bufsize > 0) and (not terminated) do
  begin
    fserial.write(buf, bufsize);
    if assigned(fontick) then
      synchronize(ontick);
    while (not terminated) do
    begin
      bufsize := 0;
      fserial.read(bufsize, sizeof(bufsize));
      if bufsize > 0 then
      begin
        break;
      end;
    end;
    bufsize := fstream.read(buf, bufsize);
    while (not fenabled) do sleep(200);
  end;

  bufsize := 255;
  fserial.write(bufsize, sizeof(bufsize));
  while true do
  begin
    bufsize := 0;
    fserial.read(bufsize, sizeof(bufsize));
    if bufsize = 255 then
    begin
      break;
    end;
  end;

  if ((not serverget(fserial, vpserver_getxcount ,i)) or (fxcount <> i)) or
     ((not serverget(fserial, vpserver_getycount ,i)) or (fycount <> i)) or
     ((not serverget(fserial, vpserver_getzcount ,i)) or (fzcount <> i)) or
     ((not serverget(fserial, vpserver_getrampkb ,i)) or (frampkb <> i)) or
     ((not serverget(fserial, vpserver_getrampkm ,i)) or (frampkm <> i)) then
  begin
    fmessage := 'Server syncing error !';
    if assigned(fonerror) then
      synchronize(fonerror);
  end;
  if assigned(foninit) then
    synchronize(foninit);
  if assigned(fonstop) then
    synchronize(fonstop);
end;

end.

