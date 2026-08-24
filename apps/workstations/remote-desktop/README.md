<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Remote Desktop Layer

This module provides the central gateway infrastructure specifically supporting graphical OS sessions.

It aggregates:
- Apache Guacamole & Tomcat
- TigerVNC 
- Chrome Remote Desktop (CRD)

By isolating the heavy JVM footprint of Tomcat/Guacamole into this foundational layer, the downstream window manager images (like `gnome`) can remain extremely thin and focused strictly on frontend Linux UX.
