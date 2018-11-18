//set maximum face size for general features
$fs=2;

//options for render:
//0 = Divided bin with rounded bottom
//1 = bulk as solid. Used to test the fit. Print w/ 2 perimeters, 0% infill
//2 = Divided bin with squared-off cavities
//3 = Replacement bin + #0
//4 = Replacement bin + #2
render = 0;

//Number of cavities (setting > 1 will create interior walls within the bin)
cols=2; //x axis (width)
rows=1; //y axis (height)

//radius of the top corners of each cavity. This is only in effect when printing 'rounded bottom' models.
inner_corner=1.75; 

//inner_offset (how far to adjust the center of the inner_corner in or out)
inner_offset=4;

//radius of corner of 'squared off' dividers. Set to 0 for sharp cornered dividers
divider_corner=0.0;

//How far below the top of the bin the internal walls should stop;
waterline=0;

//shape of the bottom of the well when making "rounded bottom" models
//a sphere is scaled to this proportion of the cavity's volume, offset by floor from the bottom, and "hull()ed" with circles of "inner_corner" radius at the top
//That shape is intersection()ed with the internal cavity volume

//starting point for fingerwells
xWell=.8;
yWell=.8;
zWell=.65;

//for 'single cavity'
xWell=1.1;
yWell=1.1;
zWell=.65;

//"wall" is the wall thickness chosen in your slicer
wall=.5;

//"shells" is how many walls/permeters to use
inner_shells=2; //thickness of internal dividers (if any)
outer_shells=0; //thickness of outside walls (if any)
//outer_shells is very negative to make the "rounded bottom" bin. Set to something sensible later

//"floor" defines depth of the floor
floor=-2;


//CHOOSE ONE SET OF WIDTH/HEIGHT values for the bin you are using
//outside dimenstions
depth=39; //constant for all sizes

//"Small Bin" (internal dimensions)
width=50.5; //x-axis
height=35.3; //y-axis

//"Medium Bin"
//width=??; 
//height=??; 

//"Large Bin"
//??

//DO NOT EDIT THE VALUES BELOW UNLESS TEST PRINTS DO NOT FIT IN YOUR BINS.
//chamfer of outer edge of an insert
chamfer=1.5; //This is chosen to match the radius of the stock bins so the inserts fit well

//draft angle of the inside of the box (degrees) Adjust if bottom of bin does not fit correctly (too tight or too loose)
draft=.9;

//find the offset from top/bottom based on the draft angle.
function draft_off(d=draft) = height/(1/tan(d));

//we will model the bulk centered around the origin, so calculate displacement of centerline of sphere used for outer 'hull()' operation
xoff=.5*width-chamfer;
yoff=.5*height-chamfer;

//The main body that will have cavities difference()-ed out of it
module bulk() {
    hull() {
        for(x = [-1,1]) {
            for(y = [-1,1]) {
                //for each quadrant
                for(z = [0,1]) {
                    //and top/bottom
                    translate([xoff*x-draft*z*x,yoff*y-draft*z*y, chamfer*z-depth*z]) {
                        if(z == 0) { //top is done with shallow circles so it is flat
                            translate([0,0,-.5]) linear_extrude(.5) circle(r=chamfer, $fn=8);
                        } else {
                            sphere(r=chamfer, $fn=8);
                        }
                    }
                }
            }
        }
    }
}

//helper to do some math
function min_max(n) = (n < 1 ? undef : ( n == 1 ? 0 : (n-1) / 2));

//distance between centers of cavities (if more than 1)
row_size = (height-wall*outer_shells)/rows + (min_max(rows) == 0 ? 1: min_max(rows))*wall*inner_shells; //y-axis
col_size = (width-wall*outer_shells)/cols + (min_max(cols) == 0 ? 1: min_max(cols))*wall*inner_shells; //x-axis

module cavities() {
    row_minmax = min_max(rows);
    col_minmax = min_max(cols);

    for (x = [col_minmax*-1:1:col_minmax]) {
        for( y = [row_minmax*-1:1:row_minmax]) {
            translate([x*col_size,y*row_size]) {
                cavity();
            }
        }
    }
}

module cavity() {
    hull() {
        for (x = [-1,1]) { for (y = [-1,1]) {
            translate([(.5*(col_size-wall*inner_shells)-inner_corner+inner_offset)*x,(.5*(row_size-wall*inner_shells)-inner_corner+inner_offset)*y, 0]) {
                translate([0,0,-.5]) linear_extrude(.6) circle(r=inner_corner,$fn=8);
        } } }
        sphere_size = col_size > row_size ? col_size : row_size;
        translate([0,0,-1*(depth-floor)+(depth-floor)*zWell*.5]) scale([col_size/sphere_size*xWell, row_size/sphere_size*yWell, (depth-floor)/sphere_size*zWell])sphere(d=sphere_size);

    }
}

module internal_walls() {
    row_minmax = min_max(rows-1);
    col_minmax = min_max(cols-1);

    if(col_minmax!=undef || row_minmax != undef)
        intersection() {
        bulk();
        union() {
            for (x = [col_minmax*-1:1:col_minmax]) {
                translate([x*col_size,0,-.5*(depth+2)]) {
                cube([wall*inner_shells,height+2, depth+2], center=true);
                }
            }
            for( y = [row_minmax*-1:1:row_minmax]) {
                translate([0,y*row_size,-.5*(depth+2)]) {
                    cube([width+2,wall*inner_shells, depth+2], center=true);
                }
            }
        }
    }
}

//recesses to allow clearance for the lid retension points.
module corners() {
    extra=4; //how far past the corner to center the spheres
    rad=18;
    excursion = 4;
    for (x = [-1,1]) { for (y = [-1,1]) {
    translate([x*(xoff+extra),y*(yoff+extra),rad-excursion]) sphere(r=rad);
    }}
}

module inner_divider() {

    union() {
        internal_walls();
        difference() {
            bulk();
            cavities();
            //corners();
        }
    }
}

if(render == 0) {
    difference() {
        inner_divider();
        //waterline determines how far from the top of the bin to cut off the tops (useful for 1x1 bin liners so they don't taper too thinly).
        cube([200,200,waterline*2],center=true);
    }
} else if (render == 1) {
    bulk();
} else if  (render == 2) {
    internal_walls();
}
//see a cross-section
//intersection() {
//inner_divider();
//translate([0,-.5*row_size,-100])cube([500,500,500]);
//}

//reference cube for size comparison
//translate([0,0,depth*.6]) cube([width, height, depth], center=true);
