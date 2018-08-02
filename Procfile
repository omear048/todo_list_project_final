#Create a file called Procfile in the root of the project with the following contents


web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
