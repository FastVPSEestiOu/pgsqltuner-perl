pgsqltuner-perl
===
[![GPL Licence](https://badges.frapsoft.com/os/gpl/gpl.png?v=102)](https://opensource.org/licenses/GPL-2.0/)    

***pgsqltuner*** -  script written in Perl that will assist you with your postgres configuration 

Usage
==
```
./pgsqltuner.pl -m memory_in_Gb -p postgres_version
# Or with autodetect
./pgsqltuner.pl
```

Example
==
```
wget --no-check-certificate -q https://raw.githubusercontent.com/FastVPSEestiOu/pgsqltuner-perl/master/pgsqltuner.pl -O - | perl
We have 6.0 Gb total memory
We have postgres 9.5
We have kernel.shmmax 32.0MB


#### Recommendations ####
checkpoint_completion_target = 0.9
effective_cache_size = 3GB
fsync = off
maintenance_work_mem = 192MB
max_wal_size = 1536MB
shared_buffers = 768MB
synchronous_commit = off
wal_buffers = 2MB
work_mem = 6MB

```

```
wget https://raw.githubusercontent.com/FastVPSEestiOu/pgsqltuner-perl/master/pgsqltuner.pl -O pgsqltuner.pl --no-check-certificate -q
chmod +x pgsqltuner.pl
./pgsqltuner.pl -m 4 -p 8.4
We have 4 Gb total memory
We have postgres 8.4
We have kernel.shmmax 32.0MB


#### Recommendations ####
checkpoint_completion_target = 0.9
checkpoint_segments = 32
effective_cache_size = 2GB
fsync = off
maintenance_work_mem = 128MB
shared_buffers = 20MB
synchronous_commit = off
wal_buffers = 1MB
work_mem = 4MB

```

Contribute
==
**pgsqltuner** young and need YOU!
* Please join us on issue track at [GitHub tracker](https://github.com/FastVPSEestiOu/pgsqltuner-perl/issues)</a>.
* Star **pgsqltuner** at [pgsqltuner Git Hub Page](https://github.com/FastVPSEestiOu/pgsqltuner-perl)
* And pull requests very welcome!
