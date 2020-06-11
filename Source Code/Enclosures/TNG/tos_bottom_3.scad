/*
    TOS Version 3 Bottom
    

*/

//Body
difference() {
    cube([41,69,6]);
    translate([5,7,2]) {
            cube([32, 55, 5]);
    }    
}

// Clasp front left
difference() {
    translate([9.0,4.5,3]) {
        cube([2.5,2,5]);
    };
    translate([9.0,4.0,0]) {
        cube([5,1,7]);
    }

    
}


 
// Clasp front right
difference() {
    translate([29.0,4.5,3]) {
        cube([2.5,2,5]);
    };
    translate([29.0,4,0]) {
        cube([5,1,7]);
    }
    
}


// Clasp back
difference() {
    translate([19.0,61.5,3]) {
        cube([2.5,2.0,5]);
    };
    translate([19.0,63,0]) {
        cube([5,1,7]);
    }    
}



//Lip
difference() {
    translate([3,5,3]) {
            cube([35.5, 58, 4]);
    }

    translate([5,7,3]) {
            cube([32, 55, 4]);
    }
}
