import sys
file=open("objects.ascii","w")
file.write(sys.argv[1]+"\n")
file.write(sys.argv[2]+" "+sys.argv[3]+" HECATE\n")
file.write(sys.argv[4]+" "+sys.argv[5]+" NED\n")
file.write(sys.argv[6]+" "+sys.argv[7]+" RC3/CNG")
