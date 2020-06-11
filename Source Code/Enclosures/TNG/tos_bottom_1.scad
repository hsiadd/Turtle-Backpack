/*
    TOS Version 1 Bottom
    

*/

//Body
cube([40,69,3]);

// Clasp front
difference() {
    translate([19.0,6.5,0]) {
        cube([2.5,5,5]);
    };
    translate([19.0,6,0]) {
        cube([5,1,4]);
    }    
}

// Clasp back
difference() {
    translate([19.0,56.5,0]) {
        cube([2.5,5,5]);
    };
    translate([19.0,61,0]) {
        cube([5,1,4]);
    }    
}

// Clasp left
/*
difference() {
    translate([2.0,32.5,0]) {
        cube([2.5,4,5]);
    };
    translate([0,32.5,-1]) {
        cube([2.5,4,5]);
    }    
}
*/




//Lip
difference() {
    translate([2.5,7,0]) {
            cube([35, 54, 4]);
    }

    translate([3.5,9,0]) {
            cube([33, 51, 4]);
    }
}
