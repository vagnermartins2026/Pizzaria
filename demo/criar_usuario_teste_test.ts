import { assert, assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import { senhaForte } from "./criar_usuario_teste.ts";
Deno.test("senha forte: 20 caracteres, 4 tipos, nunca repete", () => {
  const vistas = new Set<string>();
  for (let i = 0; i < 500; i++) {
    const s = senhaForte();
    assertEquals(s.length, 20);
    assert(/[A-Z]/.test(s) && /[a-z]/.test(s) && /[0-9]/.test(s) && /[!@#%*\-_]/.test(s), s);
    assert(!/[O0Il1]/.test(s.replace(/[2-9]/g, "")), "sem caracteres confundíveis: " + s);
    vistas.add(s);
  }
  assertEquals(vistas.size, 500);
  assertNotEquals(senhaForte(), senhaForte());
});
