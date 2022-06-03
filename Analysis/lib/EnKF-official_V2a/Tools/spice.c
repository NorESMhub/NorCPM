# include <stdio.h>

/* compute spiciness */

double p,t,s;
double spice();

main (argc,argv)
int argc;
char* argv[];
	{
	while (1)
		{
		if (argc==4)
			{
			sscanf(argv[1],"%lf",&p);
			sscanf(argv[2],"%lf",&t);
			sscanf(argv[3],"%lf",&s);
			}
		else
			{
			printf("p, t, s ? ");
			scanf("%lf %lf %lf",&p,&t,&s);
			if (feof(stdin))
				break;
			}
		printf("spice(0,t,s)\t%8.5f\n",spice(p,t,s));

		if (argc==4)
			break;
		}
	}

# include <math.h>

double spice(p,t,s)	/* pressure can only be 0 */
double p,t,s;

{
static double b[6][5];
double sp,T,S;
int i,j;

b[0][0] = 0;
b[0][1] = 7.7442e-001;
b[0][2] = -5.85e-003;
b[0][3] = -9.84e-004;
b[0][4] = -2.06e-004;

b[1][0] = 5.1655e-002;
b[1][1] = 2.034e-003;
b[1][2] = -2.742e-004;
b[1][3] = -8.5e-006;
b[1][4] = 1.36e-005;

b[2][0] = 6.64783e-003;
b[2][1] = -2.4681e-004;
b[2][2] = -1.428e-005;
b[2][3] = 3.337e-005;
b[2][4] = 7.894e-006;

b[3][0] = -5.4023e-005;
b[3][1] = 7.326e-006;
b[3][2] = 7.0036e-006;
b[3][3] = -3.0412e-006;
b[3][4] = -1.0853e-006;

b[4][0] = 3.949e-007;
b[4][1] = -3.029e-008;
b[4][2] = -3.8209e-007;
b[4][3] = 1.0012e-007;
b[4][4] = 4.7133e-008;

b[5][0] = -6.36e-010;
b[5][1] = -1.309e-009;
b[5][2] = 6.048e-009;
b[5][3] = -1.1409e-009;
b[5][4] = -6.676e-010;

s=(s-35.);
sp=0.;

T=1.;
for (i=0;i<6;i++)
	{
	S=1.;
	for(j=0;j<5;j++)
		{
		sp+=b[i][j]*T*S;
		S*=s;
		}
	T*=t;
	}

return(sp);
}

