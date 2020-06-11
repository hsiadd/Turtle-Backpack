/*
    TOS Version 1 Top
    

*/
rotate(a=[270,0,0]) {
    translate([0,20, 0]) {
        difference() {
            // Main Body Outside
            difference() {
                cylinder(h=41, r=40);
                translate([0,30,0]) {
                    cube(100, center=true);
                }
                
            };

            // Main Body Inside
            difference() {
          
                translate([0,0,3]) {
                    cylinder(h=35, r=35);
                };        
                translate([0,30,0]) {
                    cube(100, center=true);
                }

            };
            
            // Inside Recesses
            translate([29,-23,20]) {
                cube(4, center=true);
            }
            
            translate([-29,-23,20]) {
                cube(4, center=true);
            }
            
            translate([0,-23,37]) {
                cube(4, center=true);
            }
                
            translate([0,-23,4]) {
                cube(4, center=true);
            }
        }
    }
}