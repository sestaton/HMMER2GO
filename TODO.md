# list of TODOs for HMMER2GO

## `getorf` 

 - [ ] add option to choose translation table
 - [x] add option to pick one ORF if there are multiple of the same length
 - [ ] document better what the options are for reporting output ORFs
 - [ ] set default to translation=1, between START and STOP, to enforce ORFs to start with Met (issue #22)
 
## `pfamsearch`

 - [ ] limit reporting and/or fetching models by what information is available (Pfam, Seq_info, Pdb, Interpro). If
       only a model is available this may not provide well-supported evidence.

## META
 - [ ] make custom help menus that better describe usage
 - [x] make docker image to avoid installing deps
 - [ ] consider installing deps with a config class similar to how deps are 
       configured with Tephra