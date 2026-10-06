// Parametric ESP32-C3 Sensor Box (30x60x75 mm)
// All dimensions in millimeters

// ============================================================
// Parameters
// ============================================================

box_width  = 60;
box_length = 75;
box_height = 30;

wall_thick = 2.0;
lid_thick  = 2.0;
lip_height = 3.0;

// USB-C port
usb_w = 11.5;
usb_h = 7.0;

// Hex ventilation
hex_r    = 3.5;
hex_wall = 1.4;
hex_margin = 5.0;

// Perfboard mounting
board_w = 48;
board_l = 63;

standoff_h = 3.5;
standoff_r = 3.0;
standoff_hole_r = 1.0;

$fn = 32;


// ============================================================
// Derived geometry
// ============================================================

base_height = box_height - lid_thick;

hex_dx = sqrt(3) * hex_r + hex_wall;
hex_dy = 1.5 * hex_r + hex_wall;


// ============================================================
// Helper modules
// ============================================================

module hexagon(r, h) {
    cylinder(r = r, h = h, $fn = 6);
}


// ============================================================
// Hexagonal ventilation pattern
// ============================================================

module hex_grid_cutouts(
    z,
    h,
    exclude_standoffs = false
) {
    margin = wall_thick + hex_margin;

    for (y = [margin : hex_dy : box_length - margin]) {

        row = floor((y - margin) / hex_dy);
        x_shift = (row % 2 == 1) ? hex_dx / 2 : 0;

        for (x = [margin : hex_dx : box_width - margin]) {

            xx = x + x_shift;

            if (
                xx > margin &&
                xx < box_width - margin
            ) {

                allowed =
                    !exclude_standoffs ||
                    !near_standoff(xx, y);

                if (allowed) {
                    translate([xx, y, z])
                        hexagon(hex_r, h);
                }
            }
        }
    }
}


// ============================================================
// Standoff exclusion
// ============================================================

module near_standoff(x, y) {
    sx1 = (box_width - board_w) / 2;
    sx2 = sx1 + board_w;

    sy1 = (box_length - board_l) / 2;
    sy2 = sy1 + board_l;

    exclusion_r = standoff_r + hex_wall + 1.0;
}


// ============================================================
// Bottom ventilation exclusion test
// ============================================================

function inside_standoff_area(x, y) =
    let(
        sx1 = (box_width - board_w) / 2,
        sx2 = sx1 + board_w,
        sy1 = (box_length - board_l) / 2,
        sy2 = sy1 + board_l,
        r = standoff_r + hex_wall + 1.0
    )
    (sqrt((x-sx1)*(x-sx1) + (y-sy1)*(y-sy1)) < r) ||
    (sqrt((x-sx2)*(x-sx2) + (y-sy1)*(y-sy1)) < r) ||
    (sqrt((x-sx1)*(x-sx1) + (y-sy2)*(y-sy2)) < r) ||
    (sqrt((x-sx2)*(x-sx2) + (y-sy2)*(y-sy2)) < r);


// ============================================================
// Lid Module
// ============================================================

module lid() {

    difference() {

        union() {

            // 1. Grid plate (printed FIRST at Z = 0 to 2mm)
            cube([
                box_width,
                box_length,
                lid_thick
            ]);

            // 2. Friction lip (printed SECOND at Z = 2mm to 5mm)
            translate([
                wall_thick,
                wall_thick,
                lid_thick
            ])
            difference() {

                cube([
                    box_width - 2 * wall_thick,
                    box_length - 2 * wall_thick,
                    lip_height
                ]);

                translate([1.2, 1.2, -0.1])
                    cube([
                        box_width - 2 * wall_thick - 2.4,
                        box_length - 2 * wall_thick - 2.4,
                        lip_height + 0.2
                    ]);
            }
        }

        // Hex cutouts through full height
        hex_grid_cutouts(
            z = -0.5,
            h = lid_thick + lip_height + 1
        );
    }
}


// ============================================================
// Main Base Enclosure
// ============================================================

module base_box() {

    difference() {

        // Outer shell
        cube([
            box_width,
            box_length,
            base_height
        ]);

        // Interior cavity
        translate([
            wall_thick,
            wall_thick,
            wall_thick
        ])
        cube([
            box_width - 2 * wall_thick,
            box_length - 2 * wall_thick,
            base_height
        ]);

        // USB-C cutout
        translate([
            (box_width - usb_w) / 2,
            -0.1,
            wall_thick + standoff_h
        ])
        cube([
            usb_w,
            wall_thick + 0.2,
            usb_h
        ]);

        // Bottom ventilation
        for (y = [wall_thick + hex_margin :
                  hex_dy :
                  box_length - wall_thick - hex_margin]) {

            row = floor(
                (y - (wall_thick + hex_margin)) / hex_dy
            );

            x_shift =
                (row % 2 == 1)
                ? hex_dx / 2
                : 0;

            for (x = [wall_thick + hex_margin :
                      hex_dx :
                      box_width - wall_thick - hex_margin]) {

                xx = x + x_shift;

                if (
                    xx > wall_thick + hex_margin &&
                    xx < box_width - wall_thick - hex_margin &&
                    !inside_standoff_area(xx, y)
                ) {
                    translate([
                        xx,
                        y,
                        -0.1
                    ])
                    hexagon(
                        hex_r,
                        wall_thick + 0.2
                    );
                }
            }
        }
    }


    // --------------------------------------------------------
    // Four perfboard standoffs
    // --------------------------------------------------------

    sx1 = (box_width - board_w) / 2;
    sx2 = sx1 + board_w;

    sy1 = (box_length - board_l) / 2;
    sy2 = sy1 + board_l;

    for (pos = [
        [sx1, sy1],
        [sx2, sy1],
        [sx1, sy2],
        [sx2, sy2]
    ]) {

        translate([
            pos[0],
            pos[1],
            wall_thick
        ])
        difference() {

            cylinder(
                r = standoff_r,
                h = standoff_h
            );

            translate([0, 0, -0.1])
                cylinder(
                    r = standoff_hole_r,
                    h = standoff_h + 0.2
                );
        }
    }
}


// ============================================================
// Print Bed Layout (Both parts resting flat at Z = 0)
// ============================================================

// Base Box (bottom flat on bed)
base_box();

// Lid (Grid flat on bed Z=0..2mm, rim extending UP Z=2..5mm)
translate([box_width + 12, 0, 0])
    lid();
