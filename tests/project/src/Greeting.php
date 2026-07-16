<?php

namespace Example;

final class Greeting
{
public function message(string $name):string
{
return "Hello, ".$name;
}
}
