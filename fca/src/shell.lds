/* -*- text -*- */
ENTRY(_start)

MEMORY
{
  external_ram : org = 0x02000000, len = 0x40000
  work_ram :     org = 0x03000000, len = 0x8000 - 0x800
  stack :        org = 0x03007800, len = 0x800
  rom :          org = 0x08000000, len = 0x02000000
}


SECTIONS
{
  .text :
    {
      shell/*(.text.head)
      shell/*(.text);
      *(.glue_7t);
      *(.glue_7);
      _etext = .;
    } >rom
  
  .rodata :
    {
      shell/*(.rodata);
    } >rom

  . = ALIGN(4);
  .data :
    {
      _sdata = .;
      shell/*(.data);
      shell/*(.sdata);
      . = ALIGN(4);
      _edata = .;
    } >external_ram AT>rom

  _load_start = LOADADDR(.data);
  _load_end = _load_start + SIZEOF(.data);
  _rom_end = _load_end;

  .bss :
    {
      __bss_start = .;
      shell/*(.bss);
      . = ALIGN(4);
      __bss_end = .;
    } >external_ram

  .stack :
    {
      _stack = .;
      _stack_usr = . + 0x700;
      _stack_irq = . + 0x7A0;
      _stack_svc = . + 0x7E0;
      _interrupt_vector = . + 0x7FC;
    } >stack


  emu :
    {
      _emu_start = .;
      emu/*(emu.head)
      emu/*(emu.fast)
      _emu_end = .;
    } >work_ram

  emu.slow :
    {
      _emu_slow_start = .;
      emu/*(emu.slow)
      _emu_slow_end = .;
    } >external_ram

  _vram    = 0x06000000;
  _palette = 0x05000000;
  _sprite  = 0x07000000;
  _ioreg   = 0x04000000;
}
