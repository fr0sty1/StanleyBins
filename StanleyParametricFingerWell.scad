$fs=2;
//outside dimenstions

//options for render:
//0 = bin as described
//1 = bulk as solid
render = 0;

depth=39; //constant for all sizes
//using shorter height to clear registration tabs

//"Small Bin" (internal dimensions)
width=52; //x-axis
height=35.2; //y-axis

//wallThickness (set to match your slicer settings)
wall=.5; //.4 is typical

//#of 'shells' or 'perimeters'
inner_shells=2; //This multiplid by 'wall' is the total thickness of internal walls
outer_shells=-25; //the width of outer walls

//depth of the 'floor' (distance between the bottom of the well and the bottom of the model
//setting this to a larger number makes a shallower well, a negative number leaves a hole in the bottom
floor=-2;

//radius of 'interior' corners
corner=1.5;

//Number of cavities
cols=1; //x axis (width)
rows=1; //y axis (height)

//chamfer of outer edges (radius of the corners)
chamfer=1.5;

//draft angle of the inside of the box (degrees) Adjust if insert doesn't sit snugly in bin
draft=1.1;

//shape of the bottom of the well (a sphere is scaled to these proportions. Largest effect will be seen by reducing zwell to flatten the bottom out
xWell=.8;
yWell=.8;
zWell=.65;

//find the offset from top/bottom based on the draft angle.
function draft_off(d=draft) = height/(1/tan(d));

//we will model the bulk centered around the origin, so calculate centerline of sphere used for outer 'hull()' operation
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
                            translate([0,0,-.5]) linear_extrude(.5) circle(r=chamfer);
                        } else {
                            sphere(r=chamfer);
                        }
                    }
                }
            }
        }
    }
}

//helper to do some math
function min_max(n) = (n <= 1 ? 0 : (n-1) / 2);

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
            translate([(.5*(col_size-wall*inner_shells)-corner)*x,(.5*(row_size-wall*inner_shells)-corner)*y, 0]) {
                translate([0,0,-.5]) linear_extrude(.6) circle(r=corner);
        } } }
        sphere_size = col_size > row_size ? col_size : row_size;
        translate([0,0,-1*(depth-floor)+(depth-floor)*zWell*.5]) scale([col_size/sphere_size*xWell, row_size/sphere_size*yWell, (depth-floor)/sphere_size*zWell])sphere(d=sphere_size);
    }
}

module corners() {
    extra=4; //how far past the corner to center the spheres
    rad=18;
    excursion = 4;
    for (x = [-1,1]) { for (y = [-1,1]) {
    translate([x*(xoff+extra),y*(yoff+extra),rad-excursion]) sphere(r=rad);
    }}
}
module box() {
    difference() {
        bulk();
        cavities();
        corners();
    }
}

if(render == 0) {
    difference() {
        box();
        cube([200,200,(depth-18)*2],center=true);
    }
} else if (render == 1) {
    bulk();
}
//see a cross-section
//intersection() {
//box();
//translate([0,-.5*row_size,-100])cube([500,500,500]);
//}

//reference cube for size comparison
//translate([0,0,depth*.6]) cube([width, height, depth], center=true);
