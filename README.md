ansible_role-scancode-toolkit
=========

[![Build Status](https://travis-ci.org/JRemitz/ansible_role-scancode-toolkit.svg?branch=master)](https://travis-ci.org/JRemitz/ansible_role-scancode-toolkit)

This ansible role will install [scancode-toolkit](https://github.com/nexB/scancode-toolkit).

Requirements
------------

Python 2.7 is a dependency.

Role Variables
--------------

See (/defaults/main.yml)[/defaults/main.yml] for all variables.  

Directory to install scancode.

```yml
    scancode_tk_install_dir: /opt
```

Executable path

```yml
    scancode_tk_bin_path: /usr/sbin/scancode
```

Latest version to install

```yml
    scancode_tk_version: 2.2.1
```

Owner of scancode

```yml
    scancode_tk_owner: root
```

Group of scancode installation

```yml
    scancode_tk_group: root
```


Dependencies
------------

None included in the role.

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: ansible_role-scancode-toolkit }

License
-------

MIT

Author Information
------------------

Jake Remitz
