function load_environment {
    source /var/lib/jenkins/.rvm/environments/ruby-1.9.3-p392
    if [ ! -f config/application.yml ]; then
        ln -s application.yml.example config/application.yml
    fi
}

function exit_unless_master_merged {
    if [[ `git branch -a --merged origin/$BUILDKITE_BRANCH` != *origin/master* ]]; then
	echo "This branch does not have the current master merged. Please merge master and push again."
	exit 1
    fi
}

function drop_and_recreate_database {
    # Adapted from: http://stackoverflow.com/questions/12924466/capistrano-with-postgresql-error-database-is-being-accessed-by-other-users
    psql -U openfoodweb postgres <<EOF
REVOKE CONNECT ON DATABASE $1 FROM public;
ALTER DATABASE $1 CONNECTION LIMIT 0;
SELECT pg_terminate_backend(procpid)
FROM pg_stat_activity
WHERE procpid <> pg_backend_pid()
AND datname='$1';
DROP DATABASE $1;
CREATE DATABASE $1;
EOF
}
