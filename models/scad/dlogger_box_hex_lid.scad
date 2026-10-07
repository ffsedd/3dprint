// Parametric ESP32-C3 Sensor Box (Production Ready)
// All dimensions in millimeters

// ============================================================
// Parameters
// ============================================================

// STL Export Control
render_mode = "both"; // Options: "both", "base", "lid"

// Primary Enclosure Dimensions
box_length = 80;
box_width  = 60;
box_height = 30;

wall_thick = 2.0;
lid_thick  = 2.0;
lip_height = 3.0;

// ------------------------------------------------------------
// Print Tolerances & Aesthetics
// ------------------------------------------------------------
clearance       = 0.20; // Fit clearance gap between mating parts (0.15 - 0.25 mm)
corner_r        = 3.0;  // Outer vertical corner radius
bottom_chamfer  = 0.6;  // Bottom edge chamfer (prevents first-layer elephant's foot)
floor_fillet    = 1.0;  // Internal floor-to-wall strengthening radius

// Snap-Fit Lid Retention
snap_fit        = true; // Add tactile retention bumps to the friction lip
snap_bump_r     = 0.35; // Height/radius of snap detent bumps

// ------------------------------------------------------------
// Connector Settings
// ------------------------------------------------------------
connector_type   = "dc"; // Options: "usb-c", "dc", "none"
connector_wall   = "front"; // Options: "front", "back", "left", "right"
connector_offset = 0.0;     // Offset from wall center (+/- mm)
connector_pos_z  = 8.0;     // Center height from base bottom

// Cable Plug Relief Recess (thins wall around port so cable overmolds fit flush)
cable_recess     = true;
recess_depth     = 1.0; 

// DC barrel connector dimensions
dc_d = 5.5;
dc_r = dc_d / 2;

// USB-C connector dimensions
usbc_w = 9.0;
usbc_h = 3.2;

// ------------------------------------------------------------
// Hex Ventilation Pattern
// ------------------------------------------------------------
hex_r      = 3.5;
hex_wall   = 1.4;
hex_margin = 5.0;

// ------------------------------------------------------------
// Perfboard / PCB Mounting
// ------------------------------------------------------------
board_w = 48;
board_l = 63;
board_inset = 2.54; // Distance from outer board edge to mounting hole centers

standoff_h      = 3.5;
standoff_r      = 3.0;
standoff_hole_r = 1.0; // Suitable for M2 / M2.5 self-tapping screws

$fn = 32;


// ============================================================
// Derived Geometry
// ============================================================

base_height = box_height - lid_thick;

// Uniform wall thickness corner calculation
inner_r = max(0, corner_r - wall_thick);

hex_dx = sqrt(3) * hex_r + hex_wall;
hex_dy = 1.5 * hex_r + hex_wall;

// PCB Standoff Hole Center Coordinates
sx1 = (box_width - board_w) / 2 + board_inset;
sx2 = (box_width + board_w) / 2 - board_inset;
sy1 = (box_length - board_l) / 2 + board_inset;
sy2 = (box_length + board_l) / 2 - board_inset;


// ============================================================
// Helper Modules
// ============================================================

// Fast 2D rounded rectangle (vertical corners)
module rounded_rect(size, r) {
    if (r <= 0) {
        cube(size);
    } else {
        hull() {
            translate([r, r, 0]) cylinder(r=r, h=size[2]);
            translate([size[0]-r, r, 0]) cylinder(r=r, h=size[2]);
            translate([r, size[1]-r, 0]) cylinder(r=r, h=size[2]);
            translate([size[0]-r, size[1]-r, 0]) cylinder(r=r, h=size[2]);
        }
    }
}

// Rounded box with bottom chamfer to prevent 3D printing elephant's foot
module rounded_rect_chamfer(size, r, c) {
    if (c <= 0) {
        rounded_rect(size, r);
    } else {
        hull() {
            translate([c, c, 0])
                rounded_rect([size[0] - 2*c, size[1] - 2*c, 0.01], max(0.1, r - c));
            translate([0, 0, c])
                rounded_rect([size[0], size[1], size[2] - c], r);
        }
    }
}

module hexagon(r, h) {
    cylinder(r = r, h = h, $fn = 6);
}

// Connector cutout profile (includes 45° overhang roof chamfer for clean USB-C bridging)
module connector_profile() {
    depth = wall_thick + 4.0;
    if (connector_type == "dc") {
        cylinder(r = dc_r, h = depth, center = true);
    } 
    else if (connector_type == "usb-c") {
        r = usbc_h / 2;
        hull() {
            translate([-(usbc_w/2 - r), 0, 0]) cylinder(r = r, h = depth, center = true);
            translate([  usbc_w/2 - r,  0, 0]) cylinder(r = r, h = depth, center = true);
            
            // 45° roof chamfer eliminates stringing/sagging on top bridging layer
            translate([0, usbc_h/4, 0])
                cube([usbc_w - 2*r, usbc_h/2, depth], center = true);
        }
    }
}

// Cable plug relief recess cutout
module connector_recess_profile() {
    if (cable_recess && connector_type != "none") {
        rw = (connector_type == "usb-c") ? usbc_w + 5.0 : dc_d + 4.0;
        rh = (connector_type == "usb-c") ? usbc_h + 4.0 : dc_d + 4.0;
        rounded_rect([rw, recess_depth + 0.1, rh], 1.5);
    }
}

// Places connector cutout and cable recess on the selected wall
module apply_connector_cutout() {
    if (connector_type != "none") {
        rw = (connector_type == "usb-c") ? usbc_w + 5.0 : dc_d + 4.0;
        rh = (connector_type == "usb-c") ? usbc_h + 4.0 : dc_d + 4.0;

        if (connector_wall == "front") {
            translate([box_width/2 + connector_offset, 0, connector_pos_z])
                rotate([-90, 0, 0]) connector_profile();
            if (cable_recess)
                translate([box_width/2 + connector_offset - rw/2, -0.1, connector_pos_z - rh/2])
                    connector_recess_profile();
        } else if (connector_wall == "back") {
            translate([box_width/2 + connector_offset, box_length, connector_pos_z])
                rotate([90, 0, 0]) connector_profile();
            if (cable_recess)
                translate([box_width/2 + connector_offset - rw/2, box_length - recess_depth, connector_pos_z - rh/2])
                    connector_recess_profile();
        } else if (connector_wall == "left") {
            translate([0, box_length/2 + connector_offset, connector_pos_z])
                rotate([0, 90, 0]) connector_profile();
            if (cable_recess)
                translate([-0.1, box_length/2 + connector_offset - rw/2, connector_pos_z - rh/2])
                    rotate([0, 0, 90]) connector_recess_profile();
        } else if (connector_wall == "right") {
            translate([box_width, box_length/2 + connector_offset, connector_pos_z])
                rotate([0, -90, 0]) connector_profile();
            if (cable_recess)
                translate([box_width - recess_depth, box_length/2 + connector_offset - rw/2, connector_pos_z - rh/2])
                    rotate([0, 0, 90]) connector_recess_profile();
        }
    }
}


// ============================================================
// Standoff Exclusion
// ============================================================

function near_standoff(x, y) =
    let(exclusion_r = standoff_r + hex_wall + 1.0)
    (sqrt((x-sx1)*(x-sx1) + (y-sy1)*(y-sy1)) < exclusion_r) ||
    (sqrt((x-sx2)*(x-sx2) + (y-sy1)*(y-sy1)) < exclusion_r) ||
    (sqrt((x-sx1)*(x-sx1) + (y-sy2)*(y-sy2)) < exclusion_r) ||
    (sqrt((x-sx2)*(x-sx2) + (y-sy2)*(y-sy2)) < exclusion_r);


// ============================================================
// Hexagonal Ventilation Pattern (Integer Algorithm)
// ============================================================

module hex_grid_cutouts(z, h, exclude_standoffs = false) {
    margin = wall_thick + hex_margin;
    
    cols = ceil((box_width - 2 * margin) / hex_dx) + 1;
    rows = ceil((box_length - 2 * margin) / hex_dy) + 1;

    for (r = [0 : rows]) {
        y = margin + (r * hex_dy);
        x_shift = (r % 2 == 1) ? (hex_dx / 2) : 0;

        for (c = [0 : cols]) {
            x = margin + (c * hex_dx) + x_shift;

            if (x > margin && x < box_width - margin && 
                y > margin && y < box_length - margin) {

                allowed = !exclude_standoffs || !near_standoff(x, y);

                if (allowed) {
                    translate([x, y, z])
                    hexagon(hex_r, h);
                }
            }
        }
    }
}


// ============================================================
// Lid Module
// ============================================================

module lid() {
    lip_w = box_width - 2 * wall_thick - 2 * clearance;
    lip_l = box_length - 2 * wall_thick - 2 * clearance;
    lip_r = max(0, inner_r - clearance);

    difference() {
        union() {
            // 1. Grid plate (with Elephant's Foot Chamfer)
            rounded_rect_chamfer([box_width, box_length, lid_thick], corner_r, bottom_chamfer);

            // 2. Friction lip (With Clearance & Corner Radii)
            translate([wall_thick + clearance, wall_thick + clearance, lid_thick])
            difference() {
                rounded_rect([lip_w, lip_l, lip_height], lip_r);

                // Inner hollow of the lip
                translate([1.2, 1.2, -0.1])
                rounded_rect([
                    lip_w - 2.4,
                    lip_l - 2.4,
                    lip_height + 0.2
                ], max(0, lip_r - 1.2));
            }

            // 3. Optional Snap-Fit Detent Bumps
            if (snap_fit) {
                lip_center_x = box_width / 2;
                lip_center_y = box_length / 2;
                bump_z = lid_thick + lip_height / 2;

                // Lateral detent spheres on lip walls
                translate([wall_thick + clearance, lip_center_y, bump_z])
                    sphere(r = snap_bump_r);
                translate([box_width - wall_thick - clearance, lip_center_y, bump_z])
                    sphere(r = snap_bump_r);
                translate([lip_center_x, wall_thick + clearance, bump_z])
                    sphere(r = snap_bump_r);
                translate([lip_center_x, box_length - wall_thick - clearance, bump_z])
                    sphere(r = snap_bump_r);
            }
        }

        // Hexagonal ventilation holes
        hex_grid_cutouts(
            z = -0.5,
            h = lid_thick + lip_height + 1.0
        );
    }
}


// ============================================================
// Main Base Enclosure
// ============================================================

module base_box() {
    difference() {

        // Outer shell (with Elephant's Foot Chamfer)
        rounded_rect_chamfer([box_width, box_length, base_height], corner_r, bottom_chamfer);

        // Interior cavity (using calculated inner_r for uniform wall thickness)
        translate([wall_thick, wall_thick, wall_thick])
        rounded_rect([
            box_width - 2 * wall_thick,
            box_length - 2 * wall_thick,
            base_height
        ], inner_r);

        // Wall Connector Cutout & Cable Recess
        apply_connector_cutout();

        // Bottom ventilation
        hex_grid_cutouts(
            z = -0.1,
            h = wall_thick + 0.2,
            exclude_standoffs = true
        );
    }

    // Interior floor-to-wall strengthening fillets
    if (floor_fillet > 0) {
        translate([wall_thick, wall_thick, wall_thick])
        difference() {
            rounded_rect([
                box_width - 2*wall_thick, 
                box_length - 2*wall_thick, 
                floor_fillet
            ], inner_r);
            
            translate([floor_fillet, floor_fillet, -0.1])
            rounded_rect([
                box_width - 2*wall_thick - 2*floor_fillet, 
                box_length - 2*wall_thick - 2*floor_fillet, 
                floor_fillet + 0.2
            ], max(0, inner_r - floor_fillet));
        }
    }

    // Perfboard standoffs
    for (pos = [[sx1, sy1], [sx2, sy1], [sx1, sy2], [sx2, sy2]]) {
        translate([pos[0], pos[1], wall_thick])
        difference() {
            cylinder(r = standoff_r, h = standoff_h);

            // Screw hole
            translate([0, 0, -0.1])
            cylinder(r = standoff_hole_r, h = standoff_h + 0.2);
            
            // Screw thread lead-in chamfer
            translate([0, 0, standoff_h - 0.5])
            cylinder(r1 = standoff_hole_r, r2 = standoff_hole_r + 0.6, h = 0.6);
        }
    }
}


// ============================================================
// Layout / Render Execution
// ============================================================

if (render_mode == "base" || render_mode == "both") {
    base_box();
}

if (render_mode == "lid") {
    lid();
} else if (render_mode == "both") {
    translate([box_width + 12, 0, 0])
        lid();
}
