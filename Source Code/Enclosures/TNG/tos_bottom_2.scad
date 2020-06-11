/*
    TOS Version 2 Bottom
    

*/

//Body
difference() {
    cube([40,69,5]);
    translate([3.5,9,2]) {
            cube([33, 51, 4]);
    }    
}

// Clasp front
difference() {
    translate([19.0,6.25,2]) {
        cube([2.5,2.5,5]);
    };
    translate([19.0,6,0]) {
        cube([5,1,6]);
    }    
}

// Clasp back
difference() {
    translate([19.0,60.0,2]) {
        cube([2.5,4,5]);
    };
    translate([19.0,63,0]) {
        cube([5,1,6]);
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
    translate([3,7,2]) {
            cube([34, 56, 4]);
    }

    translate([4,9,2]) {
            cube([32, 51, 4]);
    }
}
