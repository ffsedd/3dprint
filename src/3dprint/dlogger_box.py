from pathlib import Path

scad = r'''//
// ESP32-C3 environmental datalogger enclosure
// Nominal outside size: 60 x 75 x 30 mm (W x L x H)
//
// Designed for:
//   - ESP32-C3 Super Mini
//   - T/RH sensor
//   - pressure sensor
//   - CO2 sensor
//   - small perfboard
//
// OpenSCAD, no external libraries required.
//
// Print:
//   1. bottom()
//   2. lid()
//
// PETG recommended. 0.20 mm layer, 3 walls.
// Adjust the sensor/PCB parameters below to your actual hardware.
//

$fn = 48;

// ------------------------------------------------------------
// Main dimensions
// ------------------------------------------------------------

W = 60;
L = 75;
H = 30;

wall = 2.0;
bottom = 2.0;

lid_h = 3.0;
lid_wall = 2.0;
lid_clearance = 0.25;

// Lid ventilation
hex_d = 3.2;       // opening diameter
hex_pitch = 5.8;   // center-to-center
lid_border = 4.0;

// ------------------------------------------------------------
// PCB mounting
// ------------------------------------------------------------

// Generic small perfboard mounting area.
// Change these to match your actual perfboard.
pcb_w = 50;
pcb_l = 65;
pcb_hole_d = 3.2;
pcb_post_d = 6;
pcb_post_h = 4;

pcb_x = (W - pcb_w)/2;
pcb_y = (L - pcb_l)/2;

// Hole spacing from PCB edges.
pcb_hole_edge = 3.0;

// ------------------------------------------------------------
// ESP32 C3 Super Mini
// ------------------------------------------------------------

esp_w = 18;
esp_l = 23;
esp_h = 3.0;

// USB opening on one short wall.
// Set to false if USB access is not required.
usb_cutout = true;
usb_w = 10;
usb_h = 5;
usb_z = 4;

// ------------------------------------------------------------
// Helpers
// ------------------------------------------------------------

module hex_hole(d, h) {
    cylinder(d=d, h=h, $fn=6);
}

module hex_grid(x0, x1, y0, y1, d, pitch, h) {
    dx = pitch;
    dy = pitch * sqrt(3)/2;

    for (iy = [0:ceil((y1-y0)/dy)]) {
        y = y0 + iy*dy;
        offset = (iy % 2) * dx/2;

        for (ix = [0:ceil((x1-x0)/dx)]) {
            x = x0 + ix*dx + offset;
            if (x > x0-1 && x < x1+1 && y > y0-1 && y < y1+1)
                translate([x,y,-0.5])
                    hex_hole(d, h+1);
        }
    }
}

// ------------------------------------------------------------
// Bottom enclosure
// ------------------------------------------------------------

module bottom() {
    difference() {
        // Outer shell
        cube([W,L,H]);

        // Hollow interior
        translate([wall, wall, bottom])
            cube([
                W-2*wall,
                L-2*wall,
                H-bottom+0.2
            ]);

        // USB opening, centered on front wall
        if (usb_cutout)
            translate([
                (W-usb_w)/2,
                -0.1,
                usb_z
            ])
                cube([usb_w, wall+0.2, usb_h]);
    }

    // PCB mounting posts
    for (x = [
        pcb_x + pcb_hole_edge,
        pcb_x + pcb_w - pcb_hole_edge
    ])
        for (y = [
            pcb_y + pcb_hole_edge,
            pcb_y + pcb_l - pcb_hole_edge
        ])
            translate([x,y,bottom])
                difference() {
                    cylinder(d=pcb_post_d, h=pcb_post_h);
                    translate([0,0,-0.1])
                        cylinder(d=pcb_hole_d, h=pcb_post_h+0.2);
                }

    // Low support rails keep a perfboard from touching the enclosure floor.
    translate([pcb_x, pcb_y, bottom])
        cube([2, pcb_l, 2]);

    translate([pcb_x+pcb_w-2, pcb_y, bottom])
        cube([2, pcb_l, 2]);

    translate([pcb_x, pcb_y, bottom])
        cube([pcb_w, 2, 2]);

    translate([pcb_x, pcb_y+pcb_l-2, bottom])
        cube([pcb_w, 2, 2]);
}

// ------------------------------------------------------------
// Lid
// ------------------------------------------------------------
//
// The lid is a thin ventilated plate with a perimeter flange.
// The hex grid is intentionally very open to minimize diffusion
// delay for CO2 and humidity.
//

module lid() {
    difference() {
        union() {
            // Main lid
            cube([W,L,lid_h]);

            // Downward locating flange
            translate([
                lid_wall,
                lid_wall,
                -2.0
            ])
                difference() {
                    cube([
                        W-2*lid_wall,
                        L-2*lid_wall,
                        2.0
                    ]);

                    translate([lid_clearance,lid_clearance,-0.1])
                        cube([
                            W-2*lid_wall-2*lid_clearance,
                            L-2*lid_wall-2*lid_clearance,
                            2.2
                        ]);
                }
        }

        // Hexagonal ventilation field
        translate([0,0,-0.1])
            hex_grid(
                lid_border,
                W-lid_border,
                lid_border,
                L-lid_border,
                hex_d,
                hex_pitch,
                lid_h+1
            );
    }
}

// ------------------------------------------------------------
// Optional sensor carrier
// ------------------------------------------------------------
//
// Generic removable sensor platform.
// It is intentionally not tied to a particular sensor model.
// Mount sensors here with adhesive, small screws, or headers.
//
// Uncomment sensor_carrier() if you want a separate platform.
//

module sensor_carrier(
    sx = 45,
    sy = 20,
    thickness = 1.5
) {
    difference() {
        cube([sx,sy,thickness]);

        // airflow holes
        translate([3,3,-0.1])
            hex_grid(
                3, sx-3,
                3, sy-3,
                3.0, 5.5,
                thickness+1
            );
    }
}

// ------------------------------------------------------------
// Preview / export
// ------------------------------------------------------------

// Uncomment ONE at a time for STL export.
//
// bottom();
// lid();
// sensor_carrier();

//
// Assembly preview:
//

translate([0,0,0])
    color("lightgray")
        bottom();

translate([0,0,H+3])
    color("gray")
        lid();
'''

path = Path(__file__).parents[2] / ("models/scad/dlogger_60x75x30.scad")
path.write_text(scad)
print(f"Created: {path}")
