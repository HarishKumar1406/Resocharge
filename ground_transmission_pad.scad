// =============================================================================
//  GROUND TRANSMISSION PAD ENCLOSURE - Wireless EV Charging System
// =============================================================================
//  Heavy-duty, weatherproof housing for a copper induction coil.
//
//  Parts in this file:
//    1. Housing : hollow rounded-rectangle shell (open top) with a central
//                 circular coil pocket, four corner mounting flanges, four
//                 internal lid-screw bosses and a cable entry hole.
//    2. Lid     : flat cover with a gasket groove and screw holes
//                 (optional, shown beside the housing for printing/export).
//
//  All dimensions in millimetres. Every dimension is a parameter below.
//  NOTE: Use a UV-stable, non-magnetic, non-conductive material
//        (e.g. glass-filled polymer) so the housing does not interfere with
//        the magnetic field of the coil.
// =============================================================================


/* ------------------------------ PARAMETERS ------------------------------- */

// --- Main body ---
plate_size      = 250;   // Outer X and Y size of the base plate
total_height    = 20;    // Total height of the housing
corner_radius   = 20;    // Outer corner radius of the rounded rectangle
wall_thickness  = 5;     // Wall AND floor thickness (makes the body hollow)

// --- Coil pocket (retaining ring inside the hollow housing) ---
coil_pocket_d     = 180; // Inner diameter of the circular coil pocket
coil_pocket_depth = 12;  // Pocket depth, measured from the floor surface up
coil_ring_wall    = 5;   // Thickness of the ring that retains the coil

// --- Mounting flanges (corners, for concrete ground anchors) ---
bolt_hole_d       = 8;   // Diameter of the anchor bolt holes
flange_thickness  = 8;   // Thickness of each flange (measured from the base)
flange_reach      = 12;  // How far the bolt centre sits beyond the body edge
                         // (measured along both X and Y, at each corner)
flange_pad_r      = 14;  // Outer radius of the round flange pad around the bolt

// --- Lid screw bosses (inside the cavity corners) ---
boss_d            = 12;  // Outer diameter of each internal boss
boss_pilot_d      = 3.3; // Pilot hole for an M4 self-tapping/thread-forming screw
boss_pilot_depth  = 12;  // Depth of the pilot hole

// --- Cable entry (on the +X side wall) ---
cable_hole_d      = 12;  // Diameter of the cable gland hole
cable_hole_z      = 11;  // Height of the hole centre above the housing base

// --- Lid ---
show_lid          = true; // true = also render the lid next to the housing
lid_thickness     = 5;    // Lid plate thickness
lid_screw_d       = 4.5;  // Clearance hole for the M4 lid screws
gasket_groove_w   = 2.5;  // Width of the gasket groove on the lid underside
gasket_groove_d   = 1.5;  // Depth of the gasket groove
lid_gap           = 40;   // Distance between housing and lid when shown side by side

// --- Rendering quality ---
$fn = 96;                 // Facet count for curved surfaces


/* ---------------------------- DERIVED VALUES ----------------------------- */

half_plate   = plate_size / 2;                       // Half of the outer size
inner_size   = plate_size - 2 * wall_thickness;      // Inner cavity size
inner_radius = max(corner_radius - wall_thickness, 0.5); // Inner corner radius
bolt_pos     = half_plate + flange_reach;            // Bolt centre (absolute X/Y)
boss_pos     = half_plate - wall_thickness - boss_d / 2; // Boss centre (absolute X/Y)
ring_outer_d = coil_pocket_d + 2 * coil_ring_wall;   // Outer diameter of coil ring
ring_height  = wall_thickness + coil_pocket_depth;   // Ring top above base (floor + pocket)


/* -------------------------------- MODULES -------------------------------- */

// 2D rounded rectangle centred on the origin.
module rounded_rect_2d(size, radius) {
    hull()
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (size / 2 - radius), sy * (size / 2 - radius)])
                circle(r = radius);
}

// Solid outer body (before hollowing).
module outer_body() {
    linear_extrude(height = total_height)
        rounded_rect_2d(plate_size, corner_radius);
}

// Hollow cavity: open at the top, leaves a floor of wall_thickness.
module cavity() {
    translate([0, 0, wall_thickness])
        linear_extrude(height = total_height)   // overshoots the top: open cavity
            rounded_rect_2d(inner_size, inner_radius);
}

// One corner flange: smooth hull between the body corner and a round bolt pad.
// (sx, sy) select the corner: +1 / -1 on each axis.
module flange(sx, sy) {
    linear_extrude(height = flange_thickness)
        hull() {
            // Circle that follows the rounded body corner
            translate([sx * (half_plate - corner_radius),
                       sy * (half_plate - corner_radius)])
                circle(r = corner_radius);
            // Round pad that carries the bolt hole
            translate([sx * bolt_pos, sy * bolt_pos])
                circle(r = flange_pad_r);
        }
}

// All four flanges.
module flanges() {
    for (sx = [-1, 1], sy = [-1, 1])
        flange(sx, sy);
}

// Through-holes for the anchor bolts (cut through full flange height).
module flange_holes() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * bolt_pos, sy * bolt_pos, -1])
            cylinder(d = bolt_hole_d, h = flange_thickness + 2);
}

// Cable entry hole through the +X side wall.
module cable_hole() {
    translate([half_plate - wall_thickness - 1, 0, cable_hole_z])
        rotate([0, 90, 0])
            cylinder(d = cable_hole_d, h = wall_thickness + 2);
}

// Circular coil pocket: a ring rising from the floor.
// The empty space inside it (diameter coil_pocket_d, depth coil_pocket_depth)
// is the pocket that holds the copper induction coil.
module coil_pocket_ring() {
    difference() {
        // Outer wall of the ring, standing on the floor
        translate([0, 0, wall_thickness - 0.01])
            cylinder(d = ring_outer_d, h = coil_pocket_depth + 0.01);
        // Pocket void: leaves the floor intact, open at the top
        translate([0, 0, wall_thickness])
            cylinder(d = coil_pocket_d, h = coil_pocket_depth + 1);
    }
}

// Internal screw bosses in the four cavity corners (for fixing the lid).
module lid_bosses() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * boss_pos, sy * boss_pos, 0])
            difference() {
                // Boss column, from the floor to the top of the walls
                translate([0, 0, wall_thickness - 0.01])
                    cylinder(d = boss_d, h = total_height - wall_thickness + 0.01);
                // Pilot hole drilled down from the top face
                translate([0, 0, total_height - boss_pilot_depth])
                    cylinder(d = boss_pilot_d, h = boss_pilot_depth + 1);
            }
}

// Complete housing.
module housing() {
    difference() {
        union() {
            outer_body();   // solid rounded block
            flanges();      // four corner mounting tabs
        }
        cavity();           // hollow it out (5 mm walls and floor)
        flange_holes();     // 8 mm anchor bolt holes
        cable_hole();       // cable entry through the side wall
    }
    coil_pocket_ring();     // central 180 mm coil pocket
    lid_bosses();           // lid-fixing bosses (added after hollowing)
}

// Lid with a gasket groove on its underside and four screw holes.
// Modelled upside down (underside facing up) so it prints/exports flat.
module lid() {
    difference() {
        linear_extrude(height = lid_thickness)
            rounded_rect_2d(plate_size, corner_radius);

        // Gasket groove, centred on the wall line, cut into the underside
        translate([0, 0, lid_thickness - gasket_groove_d])
            linear_extrude(height = gasket_groove_d + 1)
                difference() {
                    rounded_rect_2d(plate_size - wall_thickness + gasket_groove_w,
                                    corner_radius - (wall_thickness - gasket_groove_w) / 2);
                    rounded_rect_2d(plate_size - wall_thickness - gasket_groove_w,
                                    max(corner_radius - (wall_thickness + gasket_groove_w) / 2, 0.5));
                }

        // Screw clearance holes aligned with the housing bosses
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * boss_pos, sy * boss_pos, -1])
                cylinder(d = lid_screw_d, h = lid_thickness + 2);
    }
}


/* -------------------------------- RENDER --------------------------------- */

// Housing at the origin.
housing();

// Lid beside the housing, flipped so the gasket groove faces up.
if (show_lid)
    translate([plate_size + 2 * flange_reach + flange_pad_r + lid_gap, 0, 0])
        lid();
