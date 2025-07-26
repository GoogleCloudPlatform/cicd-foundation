// Copyright 2023-2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

'use strict';

const port = 8080
const name = process.env.NAME || 'World';

const express = require('express')
const app = express()

app.use(express.static('public'));
app.get('/', (req, res) => res.send(`Hello ${name} from NodeJS!`))

app.listen(port, () => console.log(`Listening on Port ${port}.`))
